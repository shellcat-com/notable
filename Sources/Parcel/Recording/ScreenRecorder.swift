import AppKit
import AVFoundation
import CoreMedia
import CoreVideo
import ScreenCaptureKit

/// One-display MP4 recorder. Writes the ScreenCaptureKit stream through AVFoundation so
/// pause/resume can skip samples on every supported macOS.
///
/// Video frames are appended via `AVAssetWriterInputPixelBufferAdaptor` (required for stable
/// H.264 finalize from SCStream BGRA buffers). Audio is optional: the AAC input is added only
/// when a real audio sample arrives before `startWriting`, so an empty audio track cannot
/// leave an MP4 without a `moov` atom.
@MainActor
final class ScreenRecorder: NSObject, ObservableObject {

    enum RecorderError: LocalizedError, Equatable {
        case noDisplay
        case alreadyRecording
        case notRecording
        case permissionDenied
        case noVideoFrames
        case finalizeFailed(String)

        var errorDescription: String? {
            switch self {
            case .noDisplay: return "No display is available to record."
            case .alreadyRecording: return "A recording is already in progress."
            case .notRecording: return "There is no recording in progress."
            case .permissionDenied: return "Screen Recording permission is required to record a display."
            case .noVideoFrames: return "The recording ended before any video frames were captured."
            case .finalizeFailed(let detail):
                return "The recording could not be finalized. \(detail)"
            }
        }

        static func == (lhs: RecorderError, rhs: RecorderError) -> Bool {
            switch (lhs, rhs) {
            case (.noDisplay, .noDisplay),
                 (.alreadyRecording, .alreadyRecording),
                 (.notRecording, .notRecording),
                 (.permissionDenied, .permissionDenied),
                 (.noVideoFrames, .noVideoFrames):
                return true
            case (.finalizeFailed(let a), .finalizeFailed(let b)):
                return a == b
            default:
                return false
            }
        }
    }

    @Published private(set) var isRecording = false
    @Published private(set) var isPaused = false
    @Published private(set) var elapsed: TimeInterval = 0

    var onFailure: ((Error) -> Void)?

    private var stream: SCStream?
    private var legacyWriter: LegacyRecordingWriter?
    private var destinationURL: URL?
    private var workingURL: URL?
    private var startedAt: Date?
    private var pausedAccumulated: TimeInterval = 0
    private var pauseStartedAt: Date?
    private var elapsedTimer: Timer?

    /// Stored as NSObject to keep macOS 15-only APIs out of the macOS 13 property surface.
    private var nativeObjects: [NSObject] = []

    func start(to url: URL, selection: SelectionResult? = nil) async throws {
        guard !isRecording else { throw RecorderError.alreadyRecording }
        guard ScreenRecordingPermission.isGranted else {
            throw RecorderError.permissionDenied
        }

        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        } catch {
            if !(await ScreenRecordingPermission.hasEffectiveAccess()) {
                throw RecorderError.permissionDenied
            }
            throw error
        }

        let display: SCDisplay
        if let selection {
            guard let match = content.displays.first(where: { $0.displayID == selection.screen.id }) else {
                throw RecorderError.noDisplay
            }
            display = match
        } else if let preferred = preferredDisplay(in: content) {
            display = preferred
        } else {
            throw RecorderError.noDisplay
        }

        let scale = NSScreen.screen(forDisplayID: display.displayID)?.backingScaleFactor ?? 1
        let sourceRect = selection?.rectInPoints
        let captureWidth = sourceRect?.width ?? CGFloat(display.width)
        let captureHeight = sourceRect?.height ?? CGFloat(display.height)
        let pixelSize = RecordingGeometry.pixelSize(
            captureSizeInPoints: CGSize(width: captureWidth, height: captureHeight),
            scale: scale,
            maxResolution: .current
        )
        let pixelWidth = pixelSize.width
        let pixelHeight = pixelSize.height

        let configuration = SCStreamConfiguration()
        configuration.width = pixelWidth
        configuration.height = pixelHeight
        if let sourceRect {
            configuration.sourceRect = sourceRect
        }
        configuration.minimumFrameInterval = RecordingFPS.current.frameInterval
        configuration.queueDepth = 5
        configuration.showsCursor = RecordingPreferences.showsCursor
        configuration.capturesAudio = true
        configuration.excludesCurrentProcessAudio = true
        configuration.sampleRate = 48_000
        configuration.channelCount = RecordingPreferences.recordMonoAudio ? 1 : 2
        configuration.pixelFormat = kCVPixelFormatType_32BGRA

        if #available(macOS 15.0, *) {
            configuration.showMouseClicks = RecordingPreferences.showsMouseClicks
            configuration.captureMicrophone = RecordingPreferences.capturesMicrophone
        }

        DesktopIconHider.beginSessionIfNeeded()

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let newStream = SCStream(filter: filter, configuration: configuration, delegate: nil)

        let recordingURL = Self.workingRecordingURL(for: url)
        try? FileManager.default.removeItem(at: recordingURL)

        // Always use AVAssetWriter path so pause/resume works on every supported macOS.
        let writer = try LegacyRecordingWriter(
            url: recordingURL,
            videoSize: CGSize(width: pixelWidth, height: pixelHeight),
            monoAudio: RecordingPreferences.recordMonoAudio
        )
        try newStream.addStreamOutput(writer, type: .screen, sampleHandlerQueue: writer.sampleQueue)
        try newStream.addStreamOutput(writer, type: .audio, sampleHandlerQueue: writer.sampleQueue)
        legacyWriter = writer
        nativeObjects = []

        stream = newStream
        destinationURL = url
        workingURL = recordingURL
        do {
            try await newStream.startCapture()
            isRecording = true
            isPaused = false
            startedAt = Date()
            pausedAccumulated = 0
            pauseStartedAt = nil
            elapsed = 0
            startElapsedTimer()
        } catch {
            try? FileManager.default.removeItem(at: recordingURL)
            clearState()
            throw error
        }
    }

    func pause() {
        guard isRecording, !isPaused else { return }
        isPaused = true
        pauseStartedAt = Date()
        legacyWriter?.isPaused = true
    }

    func resume() {
        guard isRecording, isPaused else { return }
        if let pauseStartedAt {
            pausedAccumulated += Date().timeIntervalSince(pauseStartedAt)
        }
        pauseStartedAt = nil
        isPaused = false
        legacyWriter?.isPaused = false
    }

    func stop() async throws -> URL {
        guard let stream, let destinationURL, let workingURL else { throw RecorderError.notRecording }
        elapsedTimer?.invalidate()
        elapsedTimer = nil

        let writer = legacyWriter
        do {
            try await stream.stopCapture()
        } catch {
            // Still attempt finalize if frames were written.
            _ = error
        }

        do {
            if let writer {
                try await writer.finish()
            }
        } catch {
            clearState()
            try? FileManager.default.removeItem(at: workingURL)
            throw error
        }

        do {
            try Self.installFinishedRecording(from: workingURL, to: destinationURL)
        } catch {
            clearState()
            try? FileManager.default.removeItem(at: workingURL)
            throw RecorderError.finalizeFailed("Could not move the completed recording into place. \(error.localizedDescription)")
        }

        clearState()
        return destinationURL
    }

    private func preferredDisplay(in content: SCShareableContent) -> SCDisplay? {
        guard !content.displays.isEmpty else { return nil }
        if let mainID = NSScreen.main?.displayID,
           let main = content.displays.first(where: { $0.displayID == mainID }) {
            return main
        }
        return content.displays.first
    }

    private func startElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let startedAt = self.startedAt else { return }
                var pauseExtra = self.pausedAccumulated
                if let pauseStartedAt = self.pauseStartedAt {
                    pauseExtra += Date().timeIntervalSince(pauseStartedAt)
                }
                self.elapsed = Date().timeIntervalSince(startedAt) - pauseExtra
            }
        }
    }

    private func fail(_ error: Error) {
        clearState()
        onFailure?(error)
    }

    private func clearState() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        isRecording = false
        isPaused = false
        elapsed = 0
        startedAt = nil
        pausedAccumulated = 0
        pauseStartedAt = nil
        stream = nil
        legacyWriter = nil
        destinationURL = nil
        workingURL = nil
        nativeObjects.removeAll()
        DesktopIconHider.endSession()
    }

    static func workingRecordingURL(for destinationURL: URL) -> URL {
        let fileExtension = destinationURL.pathExtension.isEmpty ? "mp4" : destinationURL.pathExtension
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("ParcelRecording-\(UUID().uuidString)")
            .appendingPathExtension(fileExtension)
    }

    static func installFinishedRecording(from sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        let parent = destinationURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: destinationURL.path) {
            _ = try fileManager.replaceItemAt(destinationURL, withItemAt: sourceURL)
        } else {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
        }
    }
}

struct RecordingPixelSize: Equatable {
    var width: Int
    var height: Int
}

enum RecordingGeometry {
    static func pixelSize(
        captureSizeInPoints: CGSize,
        scale: CGFloat,
        maxResolution: RecordingMaxResolution
    ) -> RecordingPixelSize {
        var pixelWidth = Int((captureSizeInPoints.width * scale).rounded())
        var pixelHeight = Int((captureSizeInPoints.height * scale).rounded())
        // H.264 requires even dimensions.
        pixelWidth = evenAtLeastTwo(pixelWidth)
        pixelHeight = evenAtLeastTwo(pixelHeight)

        if let maxEdge = maxResolution.maxLongEdge {
            let longest = max(pixelWidth, pixelHeight)
            if longest > maxEdge {
                let factor = CGFloat(maxEdge) / CGFloat(longest)
                pixelWidth = evenAtLeastTwo(Int((CGFloat(pixelWidth) * factor).rounded()))
                pixelHeight = evenAtLeastTwo(Int((CGFloat(pixelHeight) * factor).rounded()))
            }
        }

        return RecordingPixelSize(width: pixelWidth, height: pixelHeight)
    }

    private static func evenAtLeastTwo(_ value: Int) -> Int {
        max(2, value & ~1)
    }
}

@available(macOS 15.0, *)
private final class NativeRecordingDelegate: NSObject, SCRecordingOutputDelegate {
    let onFailure: (Error) -> Void

    init(onFailure: @escaping (Error) -> Void) {
        self.onFailure = onFailure
    }

    func recordingOutput(_ recordingOutput: SCRecordingOutput, didFailWithError error: Error) {
        onFailure(error)
    }
}

/// AVFoundation writer used for all macOS versions so pause/resume can skip samples.
final class LegacyRecordingWriter: NSObject, SCStreamOutput, @unchecked Sendable {
    let sampleQueue = DispatchQueue(label: "dev.parable.recording.samples")
    var isPaused = false

    private let writer: AVAssetWriter
    private let videoInput: AVAssetWriterInput
    private let pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor
    private let monoAudio: Bool
    private let videoSize: CGSize
    private var audioInput: AVAssetWriterInput?

    private var sessionStarted = false
    private var hasFinished = false
    private var videoSampleCount = 0
    private var pendingVideo: [CMSampleBuffer] = []
    private var pendingAudio: [CMSampleBuffer] = []
    private var sawAudioBeforeStart = false
    private var writerFailure: Error?
    #if DEBUG
    private var receivedVideoSampleCount = 0
    #endif

    /// After this many buffered video frames with no audio, start a video-only session.
    private let maxVideoFramesBeforeForceStart = 12

    init(url: URL, videoSize: CGSize, monoAudio: Bool = false) throws {
        self.monoAudio = monoAudio
        self.videoSize = videoSize
        writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        videoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: Int(videoSize.width.rounded()),
                AVVideoHeightKey: Int(videoSize.height.rounded()),
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 12_000_000,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                ],
            ]
        )
        videoInput.expectsMediaDataInRealTime = true
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: Int(videoSize.width.rounded()),
                kCVPixelBufferHeightKey as String: Int(videoSize.height.rounded()),
            ]
        )
        guard writer.canAdd(videoInput) else {
            throw NSError(domain: "dev.parable.recording", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "The MP4 writer could not accept its video input.",
            ])
        }
        writer.add(videoInput)
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard !isPaused, sampleBuffer.isValid, CMSampleBufferDataIsReady(sampleBuffer) else { return }
        sampleQueue.async { [weak self] in self?.append(sampleBuffer, type: type) }
    }

    #if DEBUG
    func receiveSampleForTesting(_ sampleBuffer: CMSampleBuffer, type: SCStreamOutputType) {
        guard !isPaused, sampleBuffer.isValid, CMSampleBufferDataIsReady(sampleBuffer) else { return }
        sampleQueue.async { [weak self] in self?.append(sampleBuffer, type: type) }
    }

    var videoSampleCountForTesting: Int {
        sampleQueue.sync { videoSampleCount }
    }

    var receivedVideoSampleCountForTesting: Int {
        sampleQueue.sync { receivedVideoSampleCount }
    }

    func flushSamplesForTesting() {
        sampleQueue.sync {}
    }
    #endif

    func finish() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sampleQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: ScreenRecorder.RecorderError.notRecording)
                    return
                }
                if let writerFailure = self.writerFailure {
                    continuation.resume(throwing: writerFailure)
                    return
                }
                guard !self.hasFinished else {
                    continuation.resume()
                    return
                }
                self.hasFinished = true

                if !self.sessionStarted {
                    if let startError = self.startSessionIfNeeded(force: true) {
                        self.writer.cancelWriting()
                        continuation.resume(throwing: startError)
                        return
                    }
                }

                guard self.sessionStarted, self.videoSampleCount > 0 else {
                    self.writer.cancelWriting()
                    continuation.resume(throwing: ScreenRecorder.RecorderError.noVideoFrames)
                    return
                }

                if self.writer.status == .failed {
                    let detail = self.writer.error?.localizedDescription ?? "Writer failed during capture."
                    continuation.resume(throwing: ScreenRecorder.RecorderError.finalizeFailed(detail))
                    return
                }

                self.videoInput.markAsFinished()
                self.audioInput?.markAsFinished()

                self.writer.finishWriting {
                    if self.writer.status == .completed {
                        continuation.resume()
                    } else {
                        let detail = self.writer.error?.localizedDescription
                            ?? "Unknown writer error (status \(self.writer.status.rawValue))."
                        continuation.resume(throwing: ScreenRecorder.RecorderError.finalizeFailed(detail))
                    }
                }
            }
        }
    }

    private func append(_ sampleBuffer: CMSampleBuffer, type: SCStreamOutputType) {
        guard !hasFinished else { return }
        switch type {
        case .screen:
            #if DEBUG
            receivedVideoSampleCount += 1
            #endif
            if !sessionStarted {
                pendingVideo.append(sampleBuffer)
                let force = pendingVideo.count >= maxVideoFramesBeforeForceStart
                if let error = startSessionIfNeeded(force: force) {
                    writerFailure = error
                    hasFinished = true
                    writer.cancelWriting()
                    NSLog("Parcel recording writer failed to start: %@", error.localizedDescription)
                }
                return
            }
            appendVideo(sampleBuffer)

        case .audio:
            if !sessionStarted {
                sawAudioBeforeStart = true
                pendingAudio.append(sampleBuffer)
                if let error = startSessionIfNeeded(force: false) {
                    writerFailure = error
                    hasFinished = true
                    writer.cancelWriting()
                    NSLog("Parcel recording writer failed to start: %@", error.localizedDescription)
                }
                return
            }
            appendAudio(sampleBuffer)

        default:
            break
        }
    }

    /// Starts the writer once we have video, optionally with audio if samples arrived first.
    private func startSessionIfNeeded(force: Bool) -> Error? {
        guard !sessionStarted else { return nil }
        guard let firstVideo = pendingVideo.first else {
            return force ? ScreenRecorder.RecorderError.noVideoFrames : nil
        }
        // Wait for an early audio sample unless forced (finish or frame budget).
        if !force && !sawAudioBeforeStart {
            return nil
        }

        if sawAudioBeforeStart {
            addAudioInputIfPossible()
        }

        guard writer.startWriting() else {
            return writer.error ?? ScreenRecorder.RecorderError.finalizeFailed("startWriting failed.")
        }
        writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(firstVideo))
        sessionStarted = true

        let videoBuffers = pendingVideo
        let audioBuffers = pendingAudio
        pendingVideo.removeAll(keepingCapacity: false)
        pendingAudio.removeAll(keepingCapacity: false)

        for buffer in videoBuffers {
            appendVideo(buffer)
        }
        for buffer in audioBuffers {
            appendAudio(buffer)
        }
        return nil
    }

    private func addAudioInputIfPossible() {
        guard audioInput == nil else { return }
        let input = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 48_000,
                AVNumberOfChannelsKey: monoAudio ? 1 : 2,
                AVEncoderBitRateKey: 160_000,
            ]
        )
        input.expectsMediaDataInRealTime = true
        guard writer.canAdd(input) else {
            sawAudioBeforeStart = false
            pendingAudio.removeAll(keepingCapacity: false)
            return
        }
        writer.add(input)
        audioInput = input
    }

    private func appendVideo(_ sampleBuffer: CMSampleBuffer) {
        guard writer.status == .writing,
              videoInput.isReadyForMoreMediaData,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }

        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        if pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: pts) {
            videoSampleCount += 1
        } else if writer.status == .failed {
            writerFailure = writer.error ?? ScreenRecorder.RecorderError.finalizeFailed("Video append failed.")
            NSLog("Parcel recording video append failed: %@", writerFailure?.localizedDescription ?? "unknown")
        }
    }

    private func appendAudio(_ sampleBuffer: CMSampleBuffer) {
        guard let audioInput, writer.status == .writing else { return }
        guard audioInput.isReadyForMoreMediaData else { return }
        if !audioInput.append(sampleBuffer), writer.status == .failed {
            writerFailure = writer.error ?? ScreenRecorder.RecorderError.finalizeFailed("Audio append failed.")
            NSLog("Parcel recording audio append failed: %@", writerFailure?.localizedDescription ?? "unknown")
        }
    }
}
