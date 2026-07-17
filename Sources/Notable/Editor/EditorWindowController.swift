import AppKit
import Combine
import SwiftUI

/// Owns one Editor `NSWindow` hosting the SwiftUI `EditorView`. Created programmatically because
/// the window carries a captured-image payload and we want explicit lifecycle control on 13.0+.
@MainActor
final class EditorWindowController: NSObject, NSWindowDelegate {

    var onClose: (() -> Void)?

    private let window: NSWindow
    private let model: EditorModel
    private let historyStore: HistoryStore
    private let historyID: UUID?
    private let historyCreatedAt: Date?
    private let historyCaptureFileName: String?
    private var historyObservation: AnyCancellable?
    private var keyMonitor: Any?
    private var historySaveFailed = false

    init(
        capture: Capture,
        historyStore: HistoryStore,
        document: CaptureDocument? = nil,
        onShowHistory: @escaping () -> Void
    ) {
        self.historyStore = historyStore
        let id = document?.id ?? historyStore.createDocument(for: capture)
        historyID = id
        historySaveFailed = document == nil && id == nil
        let entry = id.flatMap { historyStore.entry(for: $0) }
        historyCreatedAt = document?.createdAt ?? entry?.createdAt
        historyCaptureFileName = document?.captureFileName ?? entry?.captureFileName
        model = EditorModel(capture: capture, document: document)

        // Open near the Capture's point size, clamped to a sensible on-screen window.
        let point = capture.pointSize
        let chrome: CGFloat = 49 // toolbar + divider
        let maxSize = (NSScreen.main?.visibleFrame.size).map { CGSize(width: $0.width * 0.9, height: $0.height * 0.9) }
            ?? CGSize(width: 1280, height: 800)
        let contentSize = CGSize(
            width: min(max(point.width + 48, 480), maxSize.width),
            height: min(max(point.height + 48 + chrome, 320), maxSize.height)
        )

        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Notable"
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed
        window.center()

        super.init()

        window.delegate = self
        let root = EditorView(
            model: model,
            onClose: { [weak self] in self?.close() },
            onShowHistory: onShowHistory
        )
        window.contentView = NSHostingView(rootView: root)
        historyObservation = model.objectWillChange
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveHistory() }
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        installKeyMonitor()
        if historySaveFailed {
            presentHistorySaveFailure()
        }
    }

    func close() {
        window.close()
    }

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, window.isKeyWindow else { return event }
            guard event.modifierFlags.contains(.command) else { return event }
            if model.editingTextID != nil { return event }

            switch event.charactersIgnoringModifiers?.lowercased() {
            case "c":
                model.copyToClipboard()
                return nil
            case "s":
                model.save()
                return nil
            case "z":
                if event.modifierFlags.contains(.shift) {
                    model.redo()
                } else {
                    model.undo()
                }
                return nil
            case "w":
                close()
                return nil
            default:
                return event
            }
        }
    }

    private func presentHistorySaveFailure() {
        let alert = NSAlert()
        alert.messageText = "Could Not Save to Capture History"
        alert.informativeText = """
        The Editor opened normally, but this Capture could not be written to local history. \
        Copy or save your work before closing if you want to keep it.
        """
        alert.alertStyle = .warning
        alert.runModal()
    }

    // MARK: NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        saveHistory()
        historyObservation?.cancel()
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        onClose?()
    }

    private func saveHistory() {
        guard let historyID, let historyCreatedAt, let historyCaptureFileName else { return }
        historyStore.save(
            model.historyDocument(
                id: historyID,
                createdAt: historyCreatedAt,
                captureFileName: historyCaptureFileName
            )
        )
    }
}
