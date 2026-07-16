import SwiftUI

@main
struct NotableApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(coordinator: appDelegate.coordinator)
        } label: {
            // Placeholder menu bar icon — flagged in CLAUDE.md for a custom icon pass.
            Image(systemName: "viewfinder")
        }
        .menuBarExtraStyle(.menu)
    }
}
