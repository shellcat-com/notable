import SwiftUI

@main
struct ParcelApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(
                coordinator: appDelegate.coordinator,
                onCheckForUpdates: { appDelegate.checkForUpdates() }
            )
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.menu)
    }
}
