import AppKit
import SwiftUI

enum PinnedCaptureInteraction {
    static let minimumOpacity = 0.2
    static let maximumOpacity = 1.0
    static let scrollOpacityStep = 0.05

    static func clampedOpacity(_ value: Double) -> Double {
        min(maximumOpacity, max(minimumOpacity, value))
    }

    static func adjustedOpacity(current: Double, delta: Double) -> Double {
        clampedOpacity(current + delta)
    }

    static func opacityDelta(forScrollingDeltaY deltaY: CGFloat) -> Double {
        deltaY > 0 ? scrollOpacityStep : -scrollOpacityStep
    }

    static func shouldClose(eventType: NSEvent.EventType, buttonNumber: Int) -> Bool {
        eventType == .otherMouseDown || buttonNumber == 2
    }
}

struct PinnedCaptureState: Equatable {
    private(set) var opacity: Double
    private(set) var locked: Bool
    private(set) var isHidden: Bool

    init(opacity: Double = PinnedCaptureInteraction.maximumOpacity, locked: Bool = false, isHidden: Bool = false) {
        self.opacity = PinnedCaptureInteraction.clampedOpacity(opacity)
        self.locked = locked
        self.isHidden = isHidden
    }

    var ignoresMouseEvents: Bool { locked }

    mutating func setHidden(_ hidden: Bool) {
        isHidden = hidden
    }

    @discardableResult
    mutating func toggleLock() -> Bool {
        locked.toggle()
        return locked
    }

    @discardableResult
    mutating func setOpacity(_ value: Double) -> Double {
        opacity = PinnedCaptureInteraction.clampedOpacity(value)
        return opacity
    }

    @discardableResult
    mutating func adjustOpacity(by delta: Double) -> Double {
        setOpacity(opacity + delta)
    }
}

/// Always-on-top floating Capture reference (CleanShot “Pin screenshots”).
@MainActor
final class PinnedCaptureController: NSObject, NSWindowDelegate {

    var onClose: (() -> Void)?
    var onAnnotate: ((Capture) -> Void)?

    var captureForRestore: Capture { capture }

    private let capture: Capture
    private let window: NSPanel
    private var keyMonitor: Any?
    private var localMonitor: Any?
    private var state = PinnedCaptureState()

    init(capture: Capture) {
        self.capture = capture
        let point = capture.pointSize
        let width = min(max(point.width, 160), 640)
        let height = width * (point.height / max(point.width, 1))
        let size = CGSize(width: width, height: height + 28)

        window = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.isFloatingPanel = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.alphaValue = 1

        super.init()
        window.delegate = self
        refreshContent()
        positionNearCursor()
    }

    func show() {
        window.orderFrontRegardless()
        installKeyMonitor()
        installLocalMonitor()
    }

    func setHidden(_ hidden: Bool) {
        state.setHidden(hidden)
        if hidden {
            window.orderOut(nil)
        } else {
            window.orderFrontRegardless()
        }
    }

    func close() {
        teardown()
        window.orderOut(nil)
        onClose?()
    }

    func windowWillClose(_ notification: Notification) {
        teardown()
        onClose?()
    }

    // MARK: Private

    private func refreshContent() {
        let root = PinnedCaptureView(
            capture: capture,
            opacity: state.opacity,
            locked: state.locked,
            onClose: { [weak self] in self?.close() },
            onAnnotate: { [weak self] in self?.openEditor() },
            onOpacity: { [weak self] value in
                guard let self else { return }
                let opacity = state.setOpacity(value)
                window.alphaValue = opacity
            },
            onToggleLock: { [weak self] in
                guard let self else { return }
                state.toggleLock()
                window.ignoresMouseEvents = state.ignoresMouseEvents
                refreshContent()
            },
            onScrollOpacity: { [weak self] delta in
                guard let self else { return }
                let opacity = state.adjustOpacity(by: delta)
                window.alphaValue = opacity
                refreshContent()
            }
        )
        let hosting = NSHostingView(rootView: root)
        hosting.frame = window.contentLayoutRect
        hosting.autoresizingMask = [.width, .height]
        window.contentView = hosting
    }

    private func openEditor() {
        let capture = self.capture
        close()
        onAnnotate?(capture)
    }

    private func positionNearCursor() {
        let mouse = NSEvent.mouseLocation
        let size = window.frame.size
        var origin = CGPoint(x: mouse.x + 12, y: mouse.y - size.height - 12)
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main {
            let vis = screen.visibleFrame
            origin.x = min(max(origin.x, vis.minX + 8), vis.maxX - size.width - 8)
            origin.y = min(max(origin.y, vis.minY + 8), vis.maxY - size.height - 8)
        }
        window.setFrameOrigin(origin)
    }

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, window.isKeyWindow || window.isVisible else { return event }
            switch event.keyCode {
            case 53: // Esc
                close()
                return nil
            case 123: // left
                nudge(dx: event.modifierFlags.contains(.shift) ? -10 : -1, dy: 0)
                return nil
            case 124: // right
                nudge(dx: event.modifierFlags.contains(.shift) ? 10 : 1, dy: 0)
                return nil
            case 125: // down
                nudge(dx: 0, dy: event.modifierFlags.contains(.shift) ? -10 : -1)
                return nil
            case 126: // up
                nudge(dx: 0, dy: event.modifierFlags.contains(.shift) ? 10 : 1)
                return nil
            default:
                return event
            }
        }
    }

    private func installLocalMonitor() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .otherMouseDown, .scrollWheel]) { [weak self] event in
            guard let self, window.isVisible, !state.isHidden else { return event }
            let location = window.convertPoint(fromScreen: NSEvent.mouseLocation)
            guard window.contentView?.bounds.contains(location) == true || window.frame.contains(NSEvent.mouseLocation) else {
                return event
            }
            if PinnedCaptureInteraction.shouldClose(eventType: event.type, buttonNumber: event.buttonNumber) {
                close()
                return nil
            }
            if event.type == .scrollWheel {
                let delta = PinnedCaptureInteraction.opacityDelta(forScrollingDeltaY: event.scrollingDeltaY)
                let opacity = state.adjustOpacity(by: delta)
                window.alphaValue = opacity
                refreshContent()
                return nil
            }
            return event
        }
    }

    private func nudge(dx: CGFloat, dy: CGFloat) {
        var frame = window.frame
        frame.origin.x += dx
        frame.origin.y += dy
        window.setFrame(frame, display: true)
    }

    private func teardown() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }
}

// MARK: - SwiftUI

private struct PinnedCaptureView: View {
    let capture: Capture
    let opacity: Double
    let locked: Bool
    let onClose: () -> Void
    let onAnnotate: () -> Void
    let onOpacity: (Double) -> Void
    let onToggleLock: () -> Void
    let onScrollOpacity: (Double) -> Void

    @State private var localOpacity: Double

    init(
        capture: Capture,
        opacity: Double,
        locked: Bool,
        onClose: @escaping () -> Void,
        onAnnotate: @escaping () -> Void,
        onOpacity: @escaping (Double) -> Void,
        onToggleLock: @escaping () -> Void,
        onScrollOpacity: @escaping (Double) -> Void = { _ in }
    ) {
        self.capture = capture
        self.opacity = opacity
        self.locked = locked
        self.onClose = onClose
        self.onAnnotate = onAnnotate
        self.onOpacity = onOpacity
        self.onToggleLock = onToggleLock
        self.onScrollOpacity = onScrollOpacity
        _localOpacity = State(initialValue: opacity)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                Text("Pinned Capture")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                Button(action: onToggleLock) {
                    Image(systemName: locked ? "lock.fill" : "lock.open")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .help(locked ? "Unlock to interact" : "Lock — click through to apps underneath")
                Button(action: onAnnotate) {
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .help("Open in Editor")
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)

            Image(decorative: capture.image, scale: capture.scale, orientation: .up)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .onTapGesture(count: 2, perform: onAnnotate)
                .onScrollWheel { delta in
                    onScrollOpacity(PinnedCaptureInteraction.opacityDelta(forScrollingDeltaY: delta))
                }

            HStack {
                Image(systemName: "circle.lefthalf.filled")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Slider(value: $localOpacity, in: 0.2...1)
                    .controlSize(.mini)
                    .onChange(of: localOpacity) { newValue in
                        onOpacity(newValue)
                    }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
    }
}

private extension View {
    func onScrollWheel(_ handler: @escaping (CGFloat) -> Void) -> some View {
        background(ScrollWheelCatcher(handler: handler))
    }
}

private struct ScrollWheelCatcher: NSViewRepresentable {
    let handler: (CGFloat) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = ScrollWheelView()
        view.handler = handler
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? ScrollWheelView)?.handler = handler
    }

    final class ScrollWheelView: NSView {
        var handler: ((CGFloat) -> Void)?

        override func scrollWheel(with event: NSEvent) {
            handler?(event.scrollingDeltaY)
        }
    }
}
