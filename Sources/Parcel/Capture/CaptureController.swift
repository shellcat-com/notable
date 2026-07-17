import AppKit

/// Orchestrates a single Capture attempt end to end:
/// permission → freeze displays → present Overlay → crop the Selection → hand back a `Capture`.
@MainActor
final class CaptureController {

    /// Called with the finished Capture when the user confirms a Selection.
    var onCaptureComplete: ((Capture) -> Void)?
    /// Called when a Scroll Capture starts: the initial Selection and its first frozen pixels.
    var onScrollSelection: ((SelectionResult, Capture) -> Void)?
    /// Called when Screen Recording permission is missing, so the app can show guidance.
    var onNeedsPermission: (() -> Void)?
    /// Called when a Capture attempt fails after permission is granted.
    var onFailure: ((String) -> Void)?

    private let engine = CaptureEngine()
    private var overlay: OverlayController?
    private var completion: (() -> Void)?
    private var isRunning = false
    private var isScrollSelection = false

    /// `completion` always runs exactly once when the attempt finishes (commit or cancel or error).
    func begin(completion: @escaping () -> Void) {
        begin(scrollSelection: false, completion: completion)
    }

    func beginScrollSelection(completion: @escaping () -> Void) {
        begin(scrollSelection: true, completion: completion)
    }

    /// Captures every display into one stitched Canvas without showing an Overlay.
    func beginAllDisplays(completion: @escaping () -> Void) {
        guard !isRunning else { completion(); return }
        isRunning = true
        self.completion = completion
        Task { await runAllDisplays() }
    }

    private func begin(scrollSelection: Bool, completion: @escaping () -> Void) {
        guard !isRunning else { completion(); return }
        isRunning = true
        isScrollSelection = scrollSelection
        self.completion = completion
        Task { await run() }
    }

    private func run() async {
        ScreenRecordingPermission.requestIfNeeded()

        do {
            let frozen = try await engine.freezeScreens()
            presentOverlay(frozen)
        } catch {
            NSLog("Parcel: capture failed — \(error)")
            if !ScreenRecordingPermission.isGranted {
                onNeedsPermission?()
            } else {
                onFailure?("Could not freeze the screen for Capture. \(error.localizedDescription)")
            }
            finish()
        }
    }

    private func runAllDisplays() async {
        ScreenRecordingPermission.requestIfNeeded()

        do {
            let frozen = try await engine.freezeScreens()
            if let capture = engine.makeStitchedCapture(from: frozen) {
                onCaptureComplete?(capture)
            } else {
                onFailure?("Could not stitch all displays into one Capture.")
            }
        } catch {
            NSLog("Parcel: multi-display capture failed — \(error)")
            if !ScreenRecordingPermission.isGranted {
                onNeedsPermission?()
            } else {
                onFailure?("Could not capture all displays. \(error.localizedDescription)")
            }
        }
        finish()
    }

    private func presentOverlay(_ frozen: [FrozenScreen]) {
        let controller = OverlayController(screens: frozen)
        controller.onSelection = { [weak self] result in
            self?.handle(result, scroll: false)
        }
        controller.onScrollSelection = { [weak self] result in
            self?.handle(result, scroll: true)
        }
        controller.onCancel = { [weak self] in
            self?.dismissOverlay()
            self?.finish()
        }
        overlay = controller
        controller.present()
    }

    private func handle(_ result: SelectionResult, scroll: Bool) {
        dismissOverlay()
        if let capture = engine.makeCapture(from: result) {
            if scroll || isScrollSelection {
                onScrollSelection?(result, capture)
            } else {
                onCaptureComplete?(capture)
            }
        } else {
            onFailure?("The selected region was too small or outside the frozen Capture.")
        }
        finish()
    }

    private func dismissOverlay() {
        overlay?.dismiss()
        overlay = nil
    }

    private func finish() {
        isRunning = false
        isScrollSelection = false
        let done = completion
        completion = nil
        done?()
    }
}
