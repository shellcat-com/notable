import AppKit
import Combine
import UniformTypeIdentifiers

/// Central app state and wiring: owns the global hotkey, the Capture pipeline, and the Editor /
/// Preferences windows. Everything runs on the main actor.
@MainActor
final class AppCoordinator: ObservableObject {

    @Published private(set) var isCapturing = false
    @Published private(set) var isRecording = false
    @Published private(set) var isPausedRecording = false
    @Published private(set) var isStartingRecording = false
    @Published private(set) var isScrollCapturing = false
    @Published private(set) var isAddingScrollFrame = false
    @Published private(set) var scrollFrameCount = 0
    @Published private(set) var captureDelayRemaining: TimeInterval?
    @Published private(set) var recordingCountdownRemaining: TimeInterval?
    @Published private(set) var statusBanner: String?
    @Published private(set) var pinsHidden = false

    private let hotKeys = HotKeyManager()
    private let captureController = CaptureController()
    private let preferences = PreferencesWindowController()
    private let history = HistoryStore()
    private let recorder = ScreenRecorder()
    private var scrollSession: ScrollCaptureSession?
    private lazy var historyWindow = HistoryWindowController(
        store: history,
        onOpen: { [weak self] id in self?.openHistoryEntry(id) },
        onPin: { [weak self] id in self?.pinHistoryEntry(id) }
    )
    private var editors: [EditorWindowController] = []
    private var recordingEditors: [RecordingWindowController] = []
    private var quickAccess: QuickAccessOverlayController?
    private var pinnedCaptures: [PinnedCaptureController] = []
    private var recentlyClosed = RecentlyClosedCaptures()
    private var lastCapture: Capture?
    private var pendingRecordingSelection: SelectionResult?
    private let keystrokeHUD = KeystrokeHUDController()
    private let webcamPiP = WebcamPiPController()
    private var cancellables = Set<AnyCancellable>()
    private var doNotDisturbEngaged = false

    private var pendingIntent: CaptureIntent = .standard

    /// Called once from the app delegate after launch.
    func start() {
        captureController.onCaptureComplete = { [weak self] capture in
            self?.presentCapture(capture)
        }
        captureController.onScrollSelection = { [weak self] selection, initialCapture in
            guard let self else { return }
            scrollSession = ScrollCaptureSession(selection: selection, initialCapture: initialCapture)
            isScrollCapturing = true
            scrollFrameCount = 1
        }
        captureController.onNeedsPermission = { [weak self] in
            self?.openPreferences()
        }
        captureController.onFailure = { [weak self] message in
            self?.presentMessage(title: "Capture Failed", message: message)
        }
        captureController.onOCRComplete = { [weak self] text in
            self?.flashStatus("Copied \(text.count) characters of text")
        }
        captureController.onRecordingSelection = { [weak self] selection in
            self?.promptRecordingSavePanel(for: selection)
        }
        hotKeys.onAction = { [weak self] action in
            self?.handleHotKey(action)
        }
        NotificationCenter.default.publisher(for: .hotKeyPreferencesDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.hotKeys.registerDefault()
            }
            .store(in: &cancellables)
        recorder.onFailure = { [weak self] error in
            self?.stopRecordingOverlays()
            self?.isRecording = false
            self?.isPausedRecording = false
            self?.isStartingRecording = false
            self?.endDoNotDisturbIfNeeded()
            if let recorderError = error as? ScreenRecorder.RecorderError,
               recorderError == .permissionDenied {
                self?.openPreferences()
            } else {
                self?.presentError(title: "Recording Failed", error: error)
            }
        }
        hotKeys.registerDefault()
    }

    func shutdown() {
        hotKeys.unregisterAll()
        stopRecordingOverlays()
        endDoNotDisturbIfNeeded()
        DesktopIconHider.endSession()
    }

    func handleURL(_ url: URL) {
        guard CapturePreferences.urlSchemeEnabled else {
            flashStatus("URL scheme is disabled in Preferences")
            return
        }
        ParcelURLRouter.route(url, coordinator: self)
    }

    // MARK: Actions

    func beginRegionCapture() {
        pendingIntent = .standard
        beginCapture(mode: .region)
    }

    func beginWindowCapture() {
        pendingIntent = .standard
        beginCapture(mode: .window)
    }

    func beginFullscreenCapture() {
        guard !isCapturing else { return }
        pendingIntent = .standard
        isCapturing = true
        captureController.beginFullscreen { [weak self] in
            self?.isCapturing = false
        }
    }

    func beginOCRCapture() {
        pendingIntent = .standard
        beginCapture(mode: .ocr)
    }

    func beginPreviousAreaCapture() {
        guard !isCapturing, !isScrollCapturing else { return }
        pendingIntent = .standard
        isCapturing = true
        captureController.beginPreviousArea { [weak self] in
            self?.isCapturing = false
        }
    }

    func beginRegionCapture(after delay: TimeInterval) {
        guard !isCapturing else { return }
        if delay <= 0 {
            beginRegionCapture()
            return
        }
        pendingIntent = .standard
        isCapturing = true
        captureDelayRemaining = delay
        Task { [weak self] in
            var remaining = delay
            while remaining > 0 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                remaining = CountdownDisplay.nextRemaining(after: remaining)
                self?.captureDelayRemaining = remaining
            }
            self?.captureDelayRemaining = nil
            guard let self else { return }
            captureController.begin(mode: .region) { [weak self] in
                self?.isCapturing = false
                self?.captureDelayRemaining = nil
            }
        }
    }

    func beginAllDisplaysCapture() {
        guard !isCapturing else { return }
        pendingIntent = .standard
        isCapturing = true
        captureController.beginAllDisplays { [weak self] in
            self?.isCapturing = false
        }
    }

    func beginScrollCapture() {
        pendingIntent = .standard
        beginCapture(mode: .scroll)
    }

    func beginAreaCapture(rect: CGRect, displayID: CGDirectDisplayID?) {
        guard !isCapturing else { return }
        pendingIntent = .standard
        // Store as previous area then re-capture.
        if let displayID {
            CapturePreferences.lastSelectionDisplayID = displayID
        }
        CapturePreferences.lastSelectionX = rect.origin.x
        CapturePreferences.lastSelectionY = rect.origin.y
        CapturePreferences.lastSelectionWidth = rect.width
        CapturePreferences.lastSelectionHeight = rect.height
        beginPreviousAreaCapture()
    }

    private func beginCapture(mode: OverlayCaptureMode) {
        guard !isCapturing, !isScrollCapturing else { return }
        isCapturing = true
        captureController.begin(mode: mode) { [weak self] in
            self?.isCapturing = false
        }
    }

    func appendScrollCaptureFrame() {
        guard let scrollSession, isScrollCapturing, !isAddingScrollFrame else { return }
        isAddingScrollFrame = true
        Task { [weak self] in
            guard let self else { return }
            defer { isAddingScrollFrame = false }
            do {
                try await scrollSession.appendCurrentFrame()
                scrollFrameCount = scrollSession.frameCount
            } catch {
                presentError(title: "Could Not Stitch Scroll Capture", error: error)
            }
        }
    }

    func finishScrollCapture() {
        guard let scrollSession else { return }
        let capture = scrollSession.finish()
        self.scrollSession = nil
        isScrollCapturing = false
        isAddingScrollFrame = false
        scrollFrameCount = 0
        presentCapture(capture)
    }

    func cancelScrollCapture() {
        scrollSession = nil
        isScrollCapturing = false
        isAddingScrollFrame = false
        scrollFrameCount = 0
    }

    func openPreferences() {
        preferences.show()
    }

    func openHistory() {
        historyWindow.show()
    }

    func restoreRecentlyClosed() {
        guard let capture = recentlyClosed.restore() else {
            flashStatus("Nothing to restore")
            return
        }
        presentCapture(capture)
    }

    func hideAllOverlays() {
        pinsHidden.toggle()
        for pin in pinnedCaptures {
            pin.setHidden(pinsHidden)
        }
        if pinsHidden {
            quickAccess?.close()
            flashStatus("Overlays hidden")
        } else {
            flashStatus("Overlays shown")
        }
    }

    func closeAllPins() {
        let pins = pinnedCaptures
        pinnedCaptures.removeAll()
        pins.forEach { $0.close() }
    }

    func openFromClipboard() {
        let scale = NSScreen.main?.backingScaleFactor ?? 2
        guard let capture = ClipboardCaptureReader.capture(from: .general, scale: scale) else {
            flashStatus("Clipboard has no image")
            return
        }
        _ = history.createDocument(for: capture) // include external opens in History
        presentCapture(capture)
    }

    func annotateLastCapture() {
        guard let lastCapture else {
            flashStatus("No recent Capture")
            return
        }
        openEditor(with: lastCapture)
    }

    func toggleRecording() {
        if isRecording {
            if isPausedRecording {
                resumeRecording()
            } else {
                stopRecording()
            }
        } else {
            beginRecording()
        }
    }

    func pauseOrResumeRecording() {
        guard isRecording else { return }
        if isPausedRecording {
            resumeRecording()
        } else {
            pauseRecording()
        }
    }

    private func beginRecording() {
        guard !isStartingRecording, !isCapturing, !isRecording else { return }
        isCapturing = true
        captureController.beginRecordingSelection { [weak self] in
            self?.isCapturing = false
        }
    }

    /// Re-records the last recording Selection without showing the Overlay.
    func beginPreviousRecordingArea() {
        guard !isStartingRecording, !isCapturing, !isRecording else { return }
        guard CapturePreferences.hasPreviousRecordingArea else {
            flashStatus("No previous recording area")
            return
        }
        isCapturing = true
        captureController.beginPreviousRecordingArea { [weak self] in
            self?.isCapturing = false
        }
    }

    private func promptRecordingSavePanel(for selection: SelectionResult) {
        pendingRecordingSelection = selection
        let countdown = RecordingPreferences.countdownSeconds
        if countdown > 0 {
            runRecordingCountdown(seconds: countdown) { [weak self] in
                self?.startRecording(to: nil, selection: selection)
            }
            return
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.mpeg4Movie]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = recordingFileName()
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }
            startRecording(to: url, selection: selection)
        }
    }

    private func runRecordingCountdown(seconds: TimeInterval, then: @escaping () -> Void) {
        recordingCountdownRemaining = seconds
        Task { @MainActor [weak self] in
            var remaining = seconds
            while remaining > 0 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                remaining = CountdownDisplay.nextRemaining(after: remaining)
                self?.recordingCountdownRemaining = remaining
            }
            self?.recordingCountdownRemaining = nil
            then()
        }
    }

    private func startRecording(to url: URL?, selection: SelectionResult) {
        let destination: URL
        if let url {
            destination = url
        } else {
            let temp = FileManager.default.temporaryDirectory
                .appendingPathComponent(recordingFileName())
            destination = temp
        }
        isStartingRecording = true
        Task { [weak self] in
            guard let self else { return }
            do {
                try await recorder.start(to: destination, selection: selection)
                isRecording = true
                isPausedRecording = false
                beginDoNotDisturbIfNeeded()
                startRecordingOverlays()
            } catch let error as ScreenRecorder.RecorderError where error == .permissionDenied {
                openPreferences()
            } catch {
                presentError(title: "Could Not Start Recording", error: error)
            }
            isStartingRecording = false
        }
    }

    private func pauseRecording() {
        recorder.pause()
        isPausedRecording = true
        flashStatus("Recording paused")
    }

    private func resumeRecording() {
        recorder.resume()
        isPausedRecording = false
        flashStatus("Recording resumed")
    }

    func restartRecording() {
        guard isRecording, let selection = pendingRecordingSelection else { return }
        Task { [weak self] in
            guard let self else { return }
            stopRecordingOverlays()
            _ = try? await recorder.stop()
            isRecording = false
            isPausedRecording = false
            startRecording(to: nil, selection: selection)
        }
    }

    private func stopRecording() {
        Task { [weak self] in
            guard let self else { return }
            stopRecordingOverlays()
            endDoNotDisturbIfNeeded()
            do {
                let url = try await recorder.stop()
                isRecording = false
                isPausedRecording = false
                openRecordingEditor(url: url)
            } catch {
                isRecording = false
                isPausedRecording = false
                presentError(title: "Could Not Stop Recording", error: error)
            }
        }
    }

    private func startRecordingOverlays() {
        keystrokeHUD.start()
        webcamPiP.start()
    }

    private func stopRecordingOverlays() {
        keystrokeHUD.stop()
        webcamPiP.stop()
    }

    private func beginDoNotDisturbIfNeeded() {
        guard RecordingPreferences.enableDoNotDisturb, !doNotDisturbEngaged else { return }
        doNotDisturbEngaged = FocusAssist.setDoNotDisturb(true)
    }

    private func endDoNotDisturbIfNeeded() {
        guard doNotDisturbEngaged else { return }
        _ = FocusAssist.setDoNotDisturb(false)
        doNotDisturbEngaged = false
    }

    // MARK: Hotkeys

    private func handleHotKey(_ action: HotKeyManager.Action) {
        switch action {
        case .captureRegion:
            beginRegionCapture()
        case .captureCopy:
            pendingIntent = .forceCopy
            beginCapture(mode: .region)
        case .captureAnnotate:
            pendingIntent = .forceEditor
            beginCapture(mode: .region)
        case .capturePin:
            pendingIntent = .forcePin
            beginCapture(mode: .region)
        case .captureSave:
            pendingIntent = .forceSave
            beginCapture(mode: .region)
        case .capturePrevious:
            beginPreviousAreaCapture()
        case .openClipboard:
            openFromClipboard()
        case .restoreClosed:
            restoreRecentlyClosed()
        case .hideOverlays:
            hideAllOverlays()
        case .annotateLast:
            annotateLastCapture()
        case .ocr:
            beginOCRCapture()
        }
    }

    // MARK: Capture presentation

    private func presentCapture(_ capture: Capture) {
        lastCapture = capture
        ShutterSoundFeedback.playIfEnabled(CapturePreferences.playShutterSound)

        let intent = pendingIntent
        pendingIntent = .standard

        // Intent-specific actions still respect the after-Capture matrix by running it first
        // when those toggles are on, then applying the forced action.
        runAfterCaptureActions(capture, intent: intent)
    }

    private func runAfterCaptureActions(_ capture: Capture, intent: CaptureIntent) {
        let plan = AfterCapturePlan.make(preferences: .current, intent: intent)

        if plan.copy {
            copyCapture(capture)
        }
        if plan.upload {
            Task { await uploadCapture(capture) }
        }
        if plan.save {
            saveCapture(capture)
        }
        if plan.pin {
            pinCapture(capture)
        }
        if plan.openEditor {
            openEditor(with: capture)
            return
        }
        if plan.showQuickAccess {
            showQuickAccess(with: capture)
        }
    }

    private func showQuickAccess(with capture: Capture) {
        quickAccess?.close()
        let panel = QuickAccessOverlayController(capture: capture)
        panel.onAnnotate = { [weak self] capture in
            self?.quickAccess = nil
            self?.openEditor(with: capture)
        }
        panel.onPin = { [weak self] capture in
            self?.quickAccess = nil
            self?.pinCapture(capture)
        }
        panel.onDismiss = { [weak self] in
            if let panel = self?.quickAccess {
                self?.pushRecentlyClosed(panel.captureForRestore)
            }
            self?.quickAccess = nil
        }
        quickAccess = panel
        panel.show()
    }

    func pinCapture(_ capture: Capture) {
        let pinned = PinnedCaptureController(capture: capture)
        pinned.onAnnotate = { [weak self] capture in
            self?.openEditor(with: capture)
        }
        pinned.onClose = { [weak self, weak pinned] in
            if let pinned {
                self?.pushRecentlyClosed(pinned.captureForRestore)
            }
            self?.pinnedCaptures.removeAll { $0 === pinned }
        }
        pinnedCaptures.append(pinned)
        pinned.show()
        if pinsHidden {
            pinned.setHidden(true)
        }
    }

    private func copyCapture(_ capture: Capture) {
        let image = NSImage(cgImage: capture.image, size: capture.pointSize)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
        flashStatus("Copied to clipboard")
    }

    private func saveCapture(_ capture: Capture) {
        let suggested = CaptureFileName.make(extension: "png")
        if CapturePreferences.askForName {
            AskForNamePanel.present(defaultName: suggested) { [weak self] name in
                guard let name else { return }
                self?.writeCapture(capture, fileName: name.hasSuffix(".png") ? name : "\(name).png")
            }
            return
        }
        writeCapture(capture, fileName: suggested)
    }

    private func writeCapture(_ capture: Capture, fileName: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = fileName
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let rep = NSBitmapImageRep(cgImage: capture.image)
            guard let data = rep.representation(using: .png, properties: [:]) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }

    private func uploadCapture(_ capture: Capture) async {
        guard UploadPreferences.isConfigured else { return }
        let rep = NSBitmapImageRep(cgImage: capture.image)
        guard let data = rep.representation(using: .png, properties: [:]) else { return }
        do {
            let url = try await UploadService.uploadPNG(
                data: data,
                fileName: CaptureFileName.make(extension: "png")
            )
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(url.absoluteString, forType: .string)
            flashStatus("Uploaded — link copied")
        } catch {
            NSLog("Parcel: after-Capture upload failed — \(error)")
        }
    }

    private func pushRecentlyClosed(_ capture: Capture) {
        recentlyClosed.push(capture)
    }

    // MARK: Editor lifecycle

    func openEditor(with capture: Capture) {
        let controller = EditorWindowController(
            capture: capture,
            historyStore: history,
            onShowHistory: { [weak self] in self?.openHistory() }
        )
        controller.onClose = { [weak self, weak controller] in
            self?.editors.removeAll { $0 === controller }
        }
        editors.append(controller)
        controller.show()
    }

    func openParcelProject(at url: URL) {
        guard let restored = ParcelProjectIO.open(from: url) else {
            presentMessage(title: "Could Not Open Project", message: "The .parcel file could not be read.")
            return
        }
        let controller = EditorWindowController(
            capture: restored.capture,
            historyStore: history,
            document: restored.document,
            onShowHistory: { [weak self] in self?.openHistory() }
        )
        controller.onClose = { [weak self, weak controller] in
            self?.editors.removeAll { $0 === controller }
        }
        editors.append(controller)
        controller.show()
    }

    private func openHistoryEntry(_ id: UUID) {
        guard let restored = history.restore(id) else {
            presentMessage(
                title: "Could Not Open Capture History Entry",
                message: "The saved Capture could not be restored from disk. It may have been moved or corrupted."
            )
            return
        }
        let controller = EditorWindowController(
            capture: restored.capture,
            historyStore: history,
            document: restored.document,
            onShowHistory: { [weak self] in self?.openHistory() }
        )
        controller.onClose = { [weak self, weak controller] in
            self?.editors.removeAll { $0 === controller }
        }
        editors.append(controller)
        controller.show()
    }

    private func pinHistoryEntry(_ id: UUID) {
        guard let restored = history.restore(id) else { return }
        pinCapture(restored.capture)
    }

    private func openRecordingEditor(url: URL) {
        let controller = RecordingWindowController(url: url)
        controller.onClose = { [weak self, weak controller] in
            self?.recordingEditors.removeAll { $0 === controller }
        }
        recordingEditors.append(controller)
        controller.show()
    }

    private func flashStatus(_ message: String) {
        statusBanner = message
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if self?.statusBanner == message {
                self?.statusBanner = nil
            }
        }
    }

    private func presentError(title: String, error: Error) {
        let alert = NSAlert(error: error)
        alert.messageText = title
        alert.runModal()
    }

    private func presentMessage(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    private func recordingFileName() -> String {
        CaptureFileName.make(extension: "mp4")
            .replacingOccurrences(of: "Parcel ", with: "Parcel Recording ")
    }
}

// MARK: - Ask for name

enum AskForNamePanel {
    static func present(defaultName: String, completion: @escaping (String?) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Name this Capture"
        alert.informativeText = "Choose a file name, or discard."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Discard")
        let field = NSTextField(string: defaultName)
        field.frame = NSRect(x: 0, y: 0, width: 280, height: 24)
        alert.accessoryView = field
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let name = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            completion(name.isEmpty ? defaultName : name)
        } else {
            completion(nil)
        }
    }
}

// MARK: - Focus / DND best-effort

enum CountdownDisplay {
    static let tickInterval: TimeInterval = 0.1

    static func nextRemaining(after remaining: TimeInterval) -> TimeInterval {
        max(0, remaining - tickInterval)
    }

    static func captureLabel(remaining: TimeInterval) -> String {
        label(prefix: "Capturing in", remaining: remaining)
    }

    static func recordingLabel(remaining: TimeInterval) -> String {
        label(prefix: "Recording in", remaining: remaining)
    }

    private static func label(prefix: String, remaining: TimeInterval) -> String {
        "\(prefix) \(Int(ceil(max(0, remaining))))s…"
    }
}

enum FocusAssist {
    static func script(for enabled: Bool) -> String? {
        enabled ? "tell application \"System Events\" to keystroke \"d\" using {command down, option down}" : nil
    }

    /// Best-effort Focus engagement via public AppleScript shortcuts. Returns whether an attempt ran.
    @discardableResult
    static func setDoNotDisturb(_ enabled: Bool) -> Bool {
        guard let script = script(for: enabled) else { return false }
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            return error == nil
        }
        return false
    }
}
