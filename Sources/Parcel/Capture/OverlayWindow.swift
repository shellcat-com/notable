import AppKit

/// Borderless, full-screen panel that hosts the SwiftUI selection Overlay for one display.
/// Sits above normal windows (`.screenSaver` level) and can become key so it receives the drag.
final class OverlayWindow: NSPanel {

    let displayID: CGDirectDisplayID

    init(screen: NSScreen, displayID: CGDirectDisplayID) {
        self.displayID = displayID
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .screenSaver
        isMovableByWindowBackground = false
        isMovable = false
        ignoresMouseEvents = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        setFrame(screen.frame, display: true)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    // Borderless windows swallow key events by default; allow them through.
    override var acceptsFirstResponder: Bool { true }
}
