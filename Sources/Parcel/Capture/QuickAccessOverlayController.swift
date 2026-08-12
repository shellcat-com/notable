import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Floating post-Capture panel: Copy / Save / Annotate / Pin / Upload / drag-out.
@MainActor
final class QuickAccessOverlayController: NSObject, NSWindowDelegate {

    var onAnnotate: ((Capture) -> Void)?
    var onPin: ((Capture) -> Void)?
    var onDismiss: (() -> Void)?

    /// Exposed so AppCoordinator can stash recently-closed Captures.
    var captureForRestore: Capture { capture }

    private let capture: Capture
    private let isNewest: Bool
    private let window: NSPanel
    private var autoCloseTimer: Timer?
    private var dragFileURL: URL?
    private var keyMonitor: Any?

    init(capture: Capture, isNewest: Bool = true) {
        self.capture = capture
        self.isNewest = isNewest
        let size = CGSize(width: 280, height: 248)
        window = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.title = "Capture"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isFloatingPanel = true
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.96)
        window.hasShadow = true

        super.init()
        window.delegate = self

        let root = QuickAccessView(
            capture: capture,
            isNewest: isNewest,
            temporaryFileURL: { [weak self] in self?.ensureDragFile() },
            onAnnotate: { [weak self] in self?.annotate() },
            onCopy: { [weak self] in self?.copyImage() },
            onSave: { [weak self] in self?.save() },
            onPin: { [weak self] in self?.pin() },
            onUpload: { [weak self] in Task { await self?.upload() } },
            onPrint: { [weak self] in self?.printCapture() },
            onClose: { [weak self] in self?.close() },
            onSwipeDiscard: { [weak self] in self?.close() }
        )
        window.contentView = NSHostingView(rootView: root)
        positionOnScreen()
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        installKeyMonitor()
        scheduleAutoClose()
    }

    func close() {
        teardownKeys()
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        cleanupDragFile()
        window.orderOut(nil)
        onDismiss?()
    }

    func windowWillClose(_ notification: Notification) {
        teardownKeys()
        autoCloseTimer?.invalidate()
        cleanupDragFile()
        onDismiss?()
    }

    // MARK: Actions

    private func annotate() {
        autoCloseTimer?.invalidate()
        teardownKeys()
        let capture = self.capture
        window.orderOut(nil)
        onAnnotate?(capture)
        onDismiss?()
    }

    private func pin() {
        autoCloseTimer?.invalidate()
        teardownKeys()
        let capture = self.capture
        window.orderOut(nil)
        onPin?(capture)
        onDismiss?()
    }

    private func copyImage() {
        let image = NSImage(cgImage: capture.image, size: capture.pointSize)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
        scheduleAutoClose()
    }

    private func save() {
        let suggested = CaptureFileName.make(extension: "png")
        if CapturePreferences.askForName {
            AskForNamePanel.present(defaultName: suggested) { [weak self] name in
                guard let self, let name else { return }
                self.presentSavePanel(name: name.hasSuffix(".png") ? name : "\(name).png")
            }
            return
        }
        presentSavePanel(name: suggested)
    }

    private func presentSavePanel(name: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = name
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }
            self.writePNG(to: url)
            self.scheduleAutoClose()
        }
    }

    private func printCapture() {
        let image = NSImage(cgImage: capture.image, size: capture.pointSize)
        CapturePrintPayload.printOperation(for: image).run()
    }

    private func upload() async {
        guard UploadPreferences.isConfigured else { return }
        let rep = NSBitmapImageRep(cgImage: capture.image)
        guard let data = rep.representation(using: .png, properties: [:]) else { return }
        do {
            let url = try await UploadService.uploadPNG(
                data: data,
                fileName: CaptureFileName.make(extension: "png")
            )
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(url.absoluteString, forType: .string)
        } catch {
            NSLog("Parcel: Quick Access upload failed — \(error)")
        }
        scheduleAutoClose()
    }

    // MARK: Helpers

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.window.isKeyWindow else { return event }
            switch QuickAccessShortcut.action(
                charactersIgnoringModifiers: event.charactersIgnoringModifiers,
                modifierFlags: event.modifierFlags,
                keyCode: event.keyCode
            ) {
            case .copy:
                self.copyImage()
                return nil
            case .save:
                self.save()
                return nil
            case .close:
                self.close()
                return nil
            case .upload:
                Task { await self.upload() }
                return nil
            case .annotate:
                self.annotate()
                return nil
            case .printCapture:
                self.printCapture()
                return nil
            case nil:
                return event
            }
        }
    }

    private func teardownKeys() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    private func positionOnScreen() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let size = window.frame.size
        let origin = CGPoint(
            x: screen.maxX - size.width - 16,
            y: screen.minY + 16
        )
        window.setFrameOrigin(origin)
    }

    private func scheduleAutoClose() {
        autoCloseTimer?.invalidate()
        let seconds = CapturePreferences.quickAccessAutoCloseSeconds
        guard seconds > 0 else { return }
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.close() }
        }
    }

    fileprivate func ensureDragFile() -> URL? {
        if let dragFileURL { return dragFileURL }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            CaptureFileName.make(extension: "png")
        )
        writePNG(to: url)
        dragFileURL = url
        return url
    }

    private func writePNG(to url: URL) {
        let rep = NSBitmapImageRep(cgImage: capture.image)
        guard let data = rep.representation(using: .png, properties: [:]) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func cleanupDragFile() {
        if let dragFileURL {
            try? FileManager.default.removeItem(at: dragFileURL)
            self.dragFileURL = nil
        }
    }
}

enum QuickAccessShortcut: Equatable {
    case copy
    case save
    case close
    case upload
    case annotate
    case printCapture

    static func action(
        charactersIgnoringModifiers: String?,
        modifierFlags: NSEvent.ModifierFlags,
        keyCode: UInt16
    ) -> QuickAccessShortcut? {
        let mods = modifierFlags.intersection(.deviceIndependentFlagsMask)
        if mods.contains(.command) {
            switch charactersIgnoringModifiers?.lowercased() {
            case "c": return .copy
            case "s": return .save
            case "w": return .close
            case "u": return .upload
            case "e": return .annotate
            case "p": return .printCapture
            default: break
            }
        }
        if keyCode == 53 { return .close } // Esc
        return nil
    }
}

enum QuickAccessSwipe {
    static let discardThreshold: CGFloat = 80

    static func shouldDiscard(translationHeight: CGFloat) -> Bool {
        translationHeight > discardThreshold
    }
}

// MARK: - SwiftUI

private struct QuickAccessView: View {
    let capture: Capture
    let isNewest: Bool
    let temporaryFileURL: () -> URL?
    let onAnnotate: () -> Void
    let onCopy: () -> Void
    let onSave: () -> Void
    let onPin: () -> Void
    let onUpload: () -> Void
    let onPrint: () -> Void
    let onClose: () -> Void
    let onSwipeDiscard: () -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                Image(decorative: capture.image, scale: capture.scale, orientation: .up)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(isNewest ? Color.accentColor.opacity(0.7) : Color.primary.opacity(0.08), lineWidth: isNewest ? 2 : 1)
                    )
                    .onTapGesture(count: 2, perform: onAnnotate)
                    .onDrag {
                        if let url = temporaryFileURL() {
                            return NSItemProvider(contentsOf: url) ?? NSItemProvider()
                        }
                        return NSItemProvider()
                    }
                    .help("Double-click to Annotate · Drag thumbnail to share · Swipe down to discard")
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.height > 0 {
                                    dragOffset = value.translation.height
                                }
                            }
                            .onEnded { value in
                                if QuickAccessSwipe.shouldDiscard(translationHeight: value.translation.height) {
                                    onSwipeDiscard()
                                }
                                dragOffset = 0
                            }
                    )
                    .offset(y: dragOffset)

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .padding(5)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(4)
            }

            Text(sizeLabel)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                actionButton("Annotate", systemImage: "pencil.tip.crop.circle", action: onAnnotate)
                actionButton("Copy", systemImage: "doc.on.doc", action: onCopy)
                actionButton("Save", systemImage: "square.and.arrow.down", action: onSave)
            }

            HStack(spacing: 8) {
                actionButton("Pin", systemImage: "pin", action: onPin)
                if UploadPreferences.isConfigured {
                    actionButton("Upload", systemImage: "link", action: onUpload)
                }
                actionButton("Print", systemImage: "printer", action: onPrint)
            }
        }
        .padding(12)
        .frame(width: 280)
        .opacity(1 - Double(min(dragOffset, 120)) / 200)
    }

    private var sizeLabel: String {
        "\(Int(capture.pointSize.width.rounded())) × \(Int(capture.pointSize.height.rounded())) pt · ⌘C ⌘S ⌘E"
    }

    private func actionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 11, weight: .medium))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}
