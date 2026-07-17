import AppKit
import Sparkle

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    let coordinator = AppCoordinator()
    private var updaterController: SPUStandardUpdaterController!
    private lazy var welcome = WelcomeWindowController(
        onOpenPreferences: { [weak self] in self?.coordinator.openPreferences() },
        onFinish: { [weak self] in self?.markOnboardingComplete() }
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AppIdentity.migrateFromNotableIfNeeded()
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        coordinator.start()
        showOnboardingIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator.shutdown()
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    // MARK: Private

    private func showOnboardingIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: OnboardingKeys.completed) else { return }
        welcome.show()
    }

    private func markOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: OnboardingKeys.completed)
    }
}

enum OnboardingKeys {
    static let completed = "dev.parable.onboardingCompleted"
}
