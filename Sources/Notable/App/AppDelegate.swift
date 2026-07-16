import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    let coordinator = AppCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar utility: no dock icon, lives quietly in the menu bar.
        NSApp.setActivationPolicy(.accessory)
        coordinator.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator.shutdown()
    }
}
