import AppKit
import SwiftUI

/// Tracks Shift and Space key state for Canvas drawing modifiers (constrain / reposition).
struct ModifierKeyTracker: NSViewRepresentable {
    var onShiftChange: (Bool) -> Void
    var onSpaceChange: (Bool) -> Void

    func makeNSView(context: Context) -> ModifierKeyView {
        let view = ModifierKeyView()
        view.onShiftChange = onShiftChange
        view.onSpaceChange = onSpaceChange
        return view
    }

    func updateNSView(_ nsView: ModifierKeyView, context: Context) {
        nsView.onShiftChange = onShiftChange
        nsView.onSpaceChange = onSpaceChange
    }
}

final class ModifierKeyView: NSView {
    var onShiftChange: ((Bool) -> Void)?
    var onSpaceChange: ((Bool) -> Void)?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil, monitor == nil else {
            if window == nil, let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
            return
        }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown, .keyUp]) { [weak self] event in
            self?.handle(event)
            return event
        }
        publishShift(from: NSEvent.modifierFlags)
    }

    deinit {
        if let monitor { NSEvent.removeMonitor(monitor) }
    }

    private func handle(_ event: NSEvent) {
        switch event.type {
        case .flagsChanged:
            publishShift(from: event.modifierFlags)
        case .keyDown where event.keyCode == 49: // Space
            onSpaceChange?(true)
        case .keyUp where event.keyCode == 49:
            onSpaceChange?(false)
        default:
            break
        }
    }

    private func publishShift(from flags: NSEvent.ModifierFlags) {
        onShiftChange?(flags.intersection(.deviceIndependentFlagsMask).contains(.shift))
    }
}
