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
        guard !Self.isRunningUnitTests else { return }
        AppIdentity.migrateFromNotableIfNeeded()
        AppIdentity.migrateSandboxContainerDefaultsIfNeeded()
        // Never auto-start Sparkle without a real EdDSA public key — a placeholder key
        // shows “Unable to Check For Updates” and steals focus from Capture.
        let startUpdater = Self.hasValidSparklePublicKey && {
            #if DEBUG
            return false
            #else
            return true
            #endif
        }()
        updaterController = SPUStandardUpdaterController(
            startingUpdater: startUpdater,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        coordinator.start()
        showOnboardingIfNeeded()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.pathExtension == "parcel" {
                coordinator.openParcelProject(at: url)
            } else {
                coordinator.handleURL(url)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator.shutdown()
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    // MARK: Private

    private static var hasValidSparklePublicKey: Bool {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String else {
            return false
        }
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !trimmed.contains("REPLACE_WITH"),
              trimmed.count >= 40,
              Data(base64Encoded: trimmed) != nil else {
            return false
        }
        return true
    }

    private static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
    }

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
