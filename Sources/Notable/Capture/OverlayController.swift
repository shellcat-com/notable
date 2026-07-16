import AppKit
import SwiftUI

/// Presents one borderless Overlay panel per frozen display and reports the resulting Selection
/// (or a cancel). Owns the panels, the key-event monitor, and the crosshair cursor state.
@MainActor
final class OverlayController {

    var onSelection: ((SelectionResult) -> Void)?
    var onCancel: (() -> Void)?

    private let screens: [FrozenScreen]
    private var windows: [OverlayWindow] = []
    private var keyMonitor: Any?
    private var finished = false

    init(screens: [FrozenScreen]) {
        self.screens = screens
    }

    func present() {
        NSApp.activate(ignoringOtherApps: true)

        for frozen in screens {
            let window = OverlayWindow(screen: frozen.screen)
            let root = SelectionOverlayView(frozen: frozen) { [weak self] rect in
                self?.commit(SelectionResult(screen: frozen, rectInPoints: rect))
            }
            let hosting = NSHostingView(rootView: root)
            hosting.frame = window.contentLayoutRect
            hosting.autoresizingMask = [.width, .height]
            window.contentView = hosting
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }

        NSCursor.crosshair.set()

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53 { // Esc
                self.cancel()
                return nil
            }
            return event
        }
    }

    func dismiss() {
        teardown()
    }

    // MARK: Private

    private func commit(_ result: SelectionResult) {
        guard !finished else { return }
        finished = true
        onSelection?(result)
    }

    private func cancel() {
        guard !finished else { return }
        finished = true
        onCancel?()
    }

    private func teardown() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        NSCursor.arrow.set()
        for window in windows {
            window.orderOut(nil)
            window.contentView = nil
        }
        windows.removeAll()
    }
}
