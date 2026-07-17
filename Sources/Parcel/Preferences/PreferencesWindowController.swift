import AppKit
import SwiftUI

/// Owns the single Preferences window. Reuses one instance so repeated opens just refront it.
@MainActor
final class PreferencesWindowController {

    private var window: NSWindow?

    func show() {
        if let window {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Parcel Preferences"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: PreferencesView())
        window.center()
        self.window = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
