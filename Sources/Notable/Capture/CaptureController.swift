import AppKit

/// Orchestrates a single Capture attempt end to end:
/// permission → freeze displays → present Overlay → crop the Selection → hand back a `Capture`.
@MainActor
final class CaptureController {

    /// Called with the finished Capture when the user confirms a Selection.
    var onCaptureComplete: ((Capture) -> Void)?
    /// Called when Screen Recording permission is missing, so the app can show guidance.
    var onNeedsPermission: (() -> Void)?

    private let engine = CaptureEngine()
    private var overlay: OverlayController?
    private var completion: (() -> Void)?
    private var isRunning = false

    /// `completion` always runs exactly once when the attempt finishes (commit or cancel or error).
    func begin(completion: @escaping () -> Void) {
        guard !isRunning else { completion(); return }
        isRunning = true
        self.completion = completion
        Task { await run() }
    }

    private func run() async {
        guard ScreenRecordingPermission.isGranted || ScreenRecordingPermission.request() else {
            onNeedsPermission?()
            finish()
            return
        }

        do {
            let frozen = try await engine.freezeScreens()
            presentOverlay(frozen)
        } catch {
            NSLog("Notable: capture failed — \(error)")
            finish()
        }
    }

    private func presentOverlay(_ frozen: [FrozenScreen]) {
        let controller = OverlayController(screens: frozen)
        controller.onSelection = { [weak self] result in
            self?.handle(result)
        }
        controller.onCancel = { [weak self] in
            self?.dismissOverlay()
            self?.finish()
        }
        overlay = controller
        controller.present()
    }

    private func handle(_ result: SelectionResult) {
        dismissOverlay()
        if let capture = engine.makeCapture(from: result) {
            onCaptureComplete?(capture)
        }
        finish()
    }

    private func dismissOverlay() {
        overlay?.dismiss()
        overlay = nil
    }

    private func finish() {
        isRunning = false
        let done = completion
        completion = nil
        done?()
    }
}
