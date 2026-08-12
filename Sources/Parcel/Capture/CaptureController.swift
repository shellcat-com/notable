import AppKit

/// Orchestrates a single Capture attempt end to end:
/// permission → freeze displays → present Overlay → crop the Selection → hand back a `Capture`.
@MainActor
final class CaptureController {

    /// Called with the finished Capture when the user confirms a Selection.
    var onCaptureComplete: ((Capture) -> Void)?
    /// Called when a Scroll Capture starts: the initial Selection and its first frozen pixels.
    var onScrollSelection: ((SelectionResult, Capture) -> Void)?
    /// Called when the user confirms a Selection for screen recording (region pick).
    var onRecordingSelection: ((SelectionResult) -> Void)?
    /// Called after an OCR Selection copies recognized text to the clipboard.
    var onOCRComplete: ((String) -> Void)?
    /// Called when Screen Recording permission is missing, so the app can show guidance.
    var onNeedsPermission: (() -> Void)?
    /// Called when a Capture attempt fails after permission is granted.
    var onFailure: ((String) -> Void)?

    private let engine = CaptureEngine()
    private var overlay: OverlayController?
    private var completion: (() -> Void)?
    private var isRunning = false
    private var isScrollSelection = false
    private var isRecordingSelection = false
    private var initialMode: OverlayCaptureMode = .region

    /// `completion` always runs exactly once when the attempt finishes (commit or cancel or error).
    func begin(completion: @escaping () -> Void) {
        begin(mode: .region, completion: completion)
    }

    func begin(mode: OverlayCaptureMode, completion: @escaping () -> Void) {
        guard !isRunning else { completion(); return }
        isRunning = true
        initialMode = mode
        isScrollSelection = mode == .scroll
        isRecordingSelection = mode == .record
        self.completion = completion
        Task { await run() }
    }

    func beginScrollSelection(completion: @escaping () -> Void) {
        begin(mode: .scroll, completion: completion)
    }

    /// Freeze displays and present the Overlay to pick a recording region.
    func beginRecordingSelection(completion: @escaping () -> Void) {
        begin(mode: .record, completion: completion)
    }

    /// Reuses the last recording Selection rect without showing an Overlay.
    func beginPreviousRecordingArea(completion: @escaping () -> Void) {
        guard !isRunning else { completion(); return }
        guard CapturePreferences.hasPreviousRecordingArea else {
            onFailure?("No previous recording area is available yet.")
            completion()
            return
        }
        isRunning = true
        isRecordingSelection = true
        self.completion = completion
        Task { await runPreviousRecordingArea() }
    }

    /// Captures every display into one stitched Canvas without showing an Overlay.
    func beginAllDisplays(completion: @escaping () -> Void) {
        guard !isRunning else { completion(); return }
        isRunning = true
        self.completion = completion
        Task { await runAllDisplays() }
    }

    /// Captures the main display (or first frozen screen) without showing an Overlay.
    func beginFullscreen(completion: @escaping () -> Void) {
        guard !isRunning else { completion(); return }
        isRunning = true
        self.completion = completion
        Task { await runFullscreen() }
    }

    /// Re-captures the last Selection rect without showing an Overlay.
    func beginPreviousArea(completion: @escaping () -> Void) {
        guard !isRunning else { completion(); return }
        guard CapturePreferences.hasPreviousArea else {
            onFailure?("No previous Capture area is available yet.")
            completion()
            return
        }
        isRunning = true
        self.completion = completion
        Task { await runPreviousArea() }
    }

    private func run() async {
        // If TCC preflight is false, do not call ScreenCaptureKit — on recent macOS it shows
        // the same “would like to record” sheet even when Settings already lists Parcel ON
        // for a different code signature. Guide via Preferences instead.
        guard ScreenRecordingPermission.isGranted else {
            onNeedsPermission?()
            finish()
            return
        }
        DesktopIconHider.beginSessionIfNeeded()
        do {
            let frozen = try await engine.freezeScreens()
            presentOverlay(frozen)
        } catch {
            NSLog("Parcel: capture failed — \(error)")
            DesktopIconHider.endSession()
            await handleCaptureFailure(error, fallback: "Could not freeze the screen for Capture.")
            finish()
        }
    }

    private func runAllDisplays() async {
        guard ScreenRecordingPermission.isGranted else {
            onNeedsPermission?()
            finish()
            return
        }
        DesktopIconHider.beginSessionIfNeeded()
        defer { DesktopIconHider.endSession() }
        do {
            let frozen = try await engine.freezeScreens()
            if let capture = engine.makeStitchedCapture(from: frozen) {
                onCaptureComplete?(capture)
            } else {
                onFailure?("Could not stitch all displays into one Capture.")
            }
        } catch {
            NSLog("Parcel: multi-display capture failed — \(error)")
            await handleCaptureFailure(error, fallback: "Could not capture all displays.")
        }
        finish()
    }

    private func runFullscreen() async {
        guard ScreenRecordingPermission.isGranted else {
            onNeedsPermission?()
            finish()
            return
        }
        DesktopIconHider.beginSessionIfNeeded()
        defer { DesktopIconHider.endSession() }
        do {
            let frozen = try await engine.freezeScreens()
            let screen = frozen.first(where: { $0.screen == NSScreen.main }) ?? frozen.first
            guard let screen,
                  let capture = engine.makeCapture(
                    from: SelectionResult(
                        screen: screen,
                        rectInPoints: CGRect(origin: .zero, size: screen.pointSize)
                    )
                  )
            else {
                onFailure?("Could not Capture the current display.")
                finish()
                return
            }
            onCaptureComplete?(capture)
        } catch {
            NSLog("Parcel: fullscreen capture failed — \(error)")
            await handleCaptureFailure(error, fallback: "Could not Capture the current display.")
        }
        finish()
    }

    private func runPreviousArea() async {
        guard ScreenRecordingPermission.isGranted else {
            onNeedsPermission?()
            finish()
            return
        }
        DesktopIconHider.beginSessionIfNeeded()
        defer { DesktopIconHider.endSession() }
        do {
            let frozen = try await engine.freezeScreens()
            let displayID = CapturePreferences.lastSelectionDisplayID
            let rect = CapturePreferences.lastSelectionRect
            guard let screen = frozen.first(where: { $0.id == displayID }) ?? frozen.first else {
                onFailure?("The previous Capture display is no longer available.")
                finish()
                return
            }
            let clamped = rect.intersection(CGRect(origin: .zero, size: screen.pointSize))
            guard clamped.width >= 1, clamped.height >= 1,
                  let capture = engine.makeCapture(from: SelectionResult(screen: screen, rectInPoints: clamped))
            else {
                onFailure?("The previous Capture area is no longer valid on this display.")
                finish()
                return
            }
            CapturePreferences.rememberSelection(SelectionResult(screen: screen, rectInPoints: clamped))
            onCaptureComplete?(capture)
        } catch {
            NSLog("Parcel: previous-area capture failed — \(error)")
            await handleCaptureFailure(error, fallback: "Could not Capture the previous area.")
        }
        finish()
    }

    private func runPreviousRecordingArea() async {
        guard ScreenRecordingPermission.isGranted else {
            onNeedsPermission?()
            finish()
            return
        }
        do {
            let frozen = try await engine.freezeScreens()
            let displayID = CapturePreferences.lastRecordingDisplayID
            let rect = CGRect(
                x: CapturePreferences.lastRecordingX,
                y: CapturePreferences.lastRecordingY,
                width: CapturePreferences.lastRecordingWidth,
                height: CapturePreferences.lastRecordingHeight
            )
            guard let screen = frozen.first(where: { $0.id == displayID }) ?? frozen.first else {
                onFailure?("The previous recording display is no longer available.")
                finish()
                return
            }
            let clamped = rect.intersection(CGRect(origin: .zero, size: screen.pointSize))
            guard clamped.width >= 1, clamped.height >= 1 else {
                onFailure?("The previous recording area is no longer valid.")
                finish()
                return
            }
            let result = SelectionResult(screen: screen, rectInPoints: clamped)
            CapturePreferences.rememberRecordingSelection(displayID: screen.id, rect: clamped)
            // Dismiss freeze without Overlay — recording starts from frozen geometry.
            DesktopIconHider.endSession()
            onRecordingSelection?(result)
        } catch {
            NSLog("Parcel: previous recording area failed — \(error)")
            await handleCaptureFailure(error, fallback: "Could not restore the previous recording area.")
        }
        finish()
    }

    private func handleCaptureFailure(_ error: Error, fallback: String) async {
        if !ScreenRecordingPermission.isGranted {
            onNeedsPermission?()
        } else {
            // Avoid a second ScreenCaptureKit probe (it can re-show the system sheet).
            onFailure?("\(fallback) \(error.localizedDescription)")
        }
    }

    private func presentOverlay(_ frozen: [FrozenScreen]) {
        let controller = OverlayController(screens: frozen, initialMode: initialMode)
        controller.onSelection = { [weak self] result in
            self?.handle(result, kind: .region)
        }
        controller.onScrollSelection = { [weak self] result in
            self?.handle(result, kind: .scroll)
        }
        controller.onOCRSelection = { [weak self] result in
            self?.handle(result, kind: .ocr)
        }
        controller.onRecordingSelection = { [weak self] result in
            self?.handle(result, kind: .record)
        }
        controller.onCancel = { [weak self] in
            DesktopIconHider.endSession()
            self?.dismissOverlay()
            self?.finish()
        }
        overlay = controller
        controller.present()
    }

    private enum HandleKind { case region, scroll, ocr, record }

    private func handle(_ result: SelectionResult, kind: HandleKind) {
        dismissOverlay()
        DesktopIconHider.endSession()

        if kind == .record || isRecordingSelection {
            CapturePreferences.rememberRecordingSelection(
                displayID: result.screen.id,
                rect: result.rectInPoints
            )
            onRecordingSelection?(result)
            finish()
            return
        }

        if kind == .ocr {
            Task { await runOCR(from: result) }
            return
        }

        if let capture = engine.makeCapture(from: result) {
            if kind == .scroll || isScrollSelection {
                onScrollSelection?(result, capture)
            } else {
                CapturePreferences.rememberSelection(result)
                onCaptureComplete?(capture)
            }
        } else {
            onFailure?("The selected region was too small or outside the frozen Capture.")
        }
        finish()
    }

    private func runOCR(from result: SelectionResult) async {
        guard let capture = engine.makeCapture(from: result) else {
            onFailure?("The selected region was too small for OCR.")
            finish()
            return
        }
        let analysis = await VisionAnalyzer.analyze(image: capture.image, pointSize: capture.pointSize)
        let text = OCRTextFormatter.outputText(
            from: analysis.recognizedText,
            stripLineBreaks: CapturePreferences.ocrStripLineBreaks
        )
        if text.isEmpty {
            onFailure?("No text was recognized in the Selection.")
        } else {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            onOCRComplete?(text)
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
        isRecordingSelection = false
        initialMode = .region
        let done = completion
        completion = nil
        done?()
    }
}
