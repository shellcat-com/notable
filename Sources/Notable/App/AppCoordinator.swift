import AppKit
import Combine

/// Central app state and wiring: owns the global hotkey, the Capture pipeline, and the Editor /
/// Preferences windows. Everything runs on the main actor.
@MainActor
final class AppCoordinator: ObservableObject {

    @Published private(set) var isCapturing = false

    private let hotKeys = HotKeyManager()
    private let captureController = CaptureController()
    private let preferences = PreferencesWindowController()
    private var editors: [EditorWindowController] = []

    /// Called once from the app delegate after launch.
    func start() {
        captureController.onCaptureComplete = { [weak self] capture in
            self?.openEditor(with: capture)
        }
        captureController.onNeedsPermission = { [weak self] in
            self?.openPreferences()
        }
        hotKeys.onHotKey = { [weak self] in
            self?.beginRegionCapture()
        }
        hotKeys.registerDefault()
    }

    func shutdown() {
        hotKeys.unregisterAll()
    }

    // MARK: Actions

    func beginRegionCapture() {
        guard !isCapturing else { return }
        isCapturing = true
        captureController.begin { [weak self] in
            self?.isCapturing = false
        }
    }

    func openPreferences() {
        preferences.show()
    }

    // MARK: Editor lifecycle

    private func openEditor(with capture: Capture) {
        let controller = EditorWindowController(capture: capture)
        controller.onClose = { [weak self, weak controller] in
            self?.editors.removeAll { $0 === controller }
        }
        editors.append(controller)
        controller.show()
    }
}
