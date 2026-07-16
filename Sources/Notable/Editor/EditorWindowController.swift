import AppKit
import SwiftUI

/// Owns one Editor `NSWindow` hosting the SwiftUI `EditorView`. Created programmatically because
/// the window carries a captured-image payload and we want explicit lifecycle control on 13.0+.
@MainActor
final class EditorWindowController: NSObject, NSWindowDelegate {

    var onClose: (() -> Void)?

    private let window: NSWindow
    private let model: EditorModel

    init(capture: Capture) {
        model = EditorModel(capture: capture)

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
        let root = EditorView(model: model, onClose: { [weak self] in self?.close() })
        window.contentView = NSHostingView(rootView: root)
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        window.close()
    }

    // MARK: NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }
}
