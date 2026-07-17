import AppKit
import Combine
import UniformTypeIdentifiers

/// Central app state and wiring: owns the global hotkey, the Capture pipeline, and the Editor /
/// Preferences windows. Everything runs on the main actor.
@MainActor
final class AppCoordinator: ObservableObject {

    @Published private(set) var isCapturing = false
    @Published private(set) var isRecording = false
    @Published private(set) var isStartingRecording = false
    @Published private(set) var isScrollCapturing = false
    @Published private(set) var isAddingScrollFrame = false
    @Published private(set) var scrollFrameCount = 0
    @Published private(set) var captureDelayRemaining: TimeInterval?

    private let hotKeys = HotKeyManager()
    private let captureController = CaptureController()
    private let preferences = PreferencesWindowController()
    private let history = HistoryStore()
    private let recorder = ScreenRecorder()
    private var scrollSession: ScrollCaptureSession?
    private lazy var historyWindow = HistoryWindowController(store: history) { [weak self] id in
        self?.openHistoryEntry(id)
    }
    private var editors: [EditorWindowController] = []
    private var recordingEditors: [RecordingWindowController] = []

    /// Called once from the app delegate after launch.
    func start() {
        captureController.onCaptureComplete = { [weak self] capture in
            self?.openEditor(with: capture)
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
        hotKeys.onHotKey = { [weak self] in
            self?.beginRegionCapture()
        }
        NotificationCenter.default.addObserver(
            forName: .hotKeyPreferencesDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.hotKeys.registerDefault()
        }
        recorder.onFailure = { [weak self] error in
            self?.isRecording = false
            self?.isStartingRecording = false
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
    }

    // MARK: Actions

    func beginRegionCapture() {
        guard !isCapturing else { return }
        isCapturing = true
        captureController.begin { [weak self] in
            self?.isCapturing = false
        }
    }

    func beginRegionCapture(after delay: TimeInterval) {
        guard !isCapturing else { return }
        if delay <= 0 {
            beginRegionCapture()
            return
        }
        isCapturing = true
        captureDelayRemaining = delay
        Task { [weak self] in
            var remaining = delay
            while remaining > 0 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                remaining -= 0.1
                self?.captureDelayRemaining = max(0, remaining)
            }
            self?.captureDelayRemaining = nil
            guard let self else { return }
            captureController.begin { [weak self] in
                self?.isCapturing = false
                self?.captureDelayRemaining = nil
            }
        }
    }

    func beginAllDisplaysCapture() {
        guard !isCapturing else { return }
        isCapturing = true
        captureController.beginAllDisplays { [weak self] in
            self?.isCapturing = false
        }
    }

    func beginScrollCapture() {
        guard !isCapturing, !isScrollCapturing else { return }
        isCapturing = true
        captureController.beginScrollSelection { [weak self] in
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
        openEditor(with: capture)
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

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            beginRecording()
        }
    }

    private func beginRecording() {
        guard !isStartingRecording, !isCapturing else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.mpeg4Movie]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = recordingFileName()
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }
            isStartingRecording = true
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await recorder.start(to: url)
                    isRecording = true
                } catch let error as ScreenRecorder.RecorderError where error == .permissionDenied {
                    openPreferences()
                } catch {
                    presentError(title: "Could Not Start Recording", error: error)
                }
                isStartingRecording = false
            }
        }
    }

    private func stopRecording() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let url = try await recorder.stop()
                isRecording = false
                openRecordingEditor(url: url)
            } catch {
                isRecording = false
                presentError(title: "Could Not Stop Recording", error: error)
            }
        }
    }

    // MARK: Editor lifecycle

    private func openEditor(with capture: Capture) {
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

    private func openRecordingEditor(url: URL) {
        let controller = RecordingWindowController(url: url)
        controller.onClose = { [weak self, weak controller] in
            self?.recordingEditors.removeAll { $0 === controller }
        }
        recordingEditors.append(controller)
        controller.show()
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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return "Parcel Recording \(formatter.string(from: Date())).mp4"
    }
}
