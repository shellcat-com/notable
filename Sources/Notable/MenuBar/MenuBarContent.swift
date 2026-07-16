import SwiftUI

/// The menu shown from Notable's menu bar item.
struct MenuBarContent: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        Button("Capture Region") {
            coordinator.beginRegionCapture()
        }
        .keyboardShortcut("2", modifiers: [.command, .shift])

        Divider()

        Button("Preferences…") {
            coordinator.openPreferences()
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit Notable") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
