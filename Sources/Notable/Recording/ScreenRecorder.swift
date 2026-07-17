import AppKit
import AVFoundation
import CoreMedia
import ScreenCaptureKit

/// One-display MP4 recorder. macOS 15+ uses ScreenCaptureKit's native recorder; macOS 13–14
/// writes the same ScreenCaptureKit stream through AVFoundation. The output always includes
/// system audio when the system grants Screen Recording permission.
@MainActor
final class ScreenRecorder: NSObject, ObservableObject {

    enum RecorderError: LocalizedError {
        case noDisplay
        case alreadyRecording
        case notRecording
        case permissionDenied

        var errorDescription: String? {
            switch self {
            case .noDisplay: return "No display is available to record."
            case .alreadyRecording: return "A recording is already in progress."
            case .notRecording: return "There is no recording in progress."
            case .permissionDenied: return "Screen Recording permission is required to record a display."
            }
        }
    }

    @Published private(set) var isRecording = false
    @Published private(set) var elapsed: TimeInterval = 0

    var onFailure: ((Error) -> Void)?

    private var stream: SCStream?
    private var legacyWriter: LegacyRecordingWriter?
    private var destinationURL: URL?
    private var startedAt: Date?
    private var elapsedTimer: Timer?

    /// Stored as NSObject to keep macOS 15-only APIs out of the macOS 13 property surface.
    private var nativeObjects: [NSObject] = []

    func start(to url: URL) async throws {
        guard !isRecording else { throw RecorderError.alreadyRecording }
        ScreenRecordingPermission.requestIfNeeded()

        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        } catch {
            if !ScreenRecordingPermission.isGranted { throw RecorderError.permissionDenied }
            throw error
        }
        guard let display = preferredDisplay(in: content) else { throw RecorderError.noDisplay }

        let scale = NSScreen.screen(forDisplayID: display.displayID)?.backingScaleFactor ?? 1
        let configuration = SCStreamConfiguration()
        configuration.width = Int((CGFloat(display.width) * scale).rounded())
        configuration.height = Int((CGFloat(display.height) * scale).rounded())
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        configuration.queueDepth = 5
        configuration.showsCursor = true
        configuration.capturesAudio = true
        configuration.excludesCurrentProcessAudio = true
        configuration.sampleRate = 48_000
        configuration.channelCount = 2

        if #available(macOS 15.0, *) {
            configuration.showMouseClicks = true
            configuration.captureMicrophone = true
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let newStream = SCStream(filter: filter, configuration: configuration, delegate: nil)

        if #available(macOS 15.0, *) {
            let outputConfiguration = SCRecordingOutputConfiguration()
            outputConfiguration.outputURL = url
            outputConfiguration.outputFileType = .mp4
            outputConfiguration.videoCodecType = .h264

            let delegate = NativeRecordingDelegate { [weak self] error in
                Task { @MainActor in self?.fail(error) }
            }
            let output = SCRecordingOutput(configuration: outputConfiguration, delegate: delegate)
            try newStream.addRecordingOutput(output)
            nativeObjects = [output, delegate]
        } else {
            let writer = try LegacyRecordingWriter(
                url: url,
                videoSize: CGSize(width: configuration.width, height: configuration.height)
            )
            try newStream.addStreamOutput(writer, type: .screen, sampleHandlerQueue: writer.sampleQueue)
            try newStream.addStreamOutput(writer, type: .audio, sampleHandlerQueue: writer.sampleQueue)
            legacyWriter = writer
        }

        stream = newStream
        destinationURL = url
        do {
            try await newStream.startCapture()
            isRecording = true
            startedAt = Date()
            elapsed = 0
            startElapsedTimer()
        } catch {
            clearState()
            throw error
        }
    }

    func stop() async throws -> URL {
        guard let stream, let destinationURL else { throw RecorderError.notRecording }
        elapsedTimer?.invalidate()
        elapsedTimer = nil

        do {
            try await stream.stopCapture()
            if let legacyWriter {
                await legacyWriter.finish()
            }
            clearState()
            return destinationURL
        } catch {
            clearState()
            throw error
        }
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
                self.elapsed = Date().timeIntervalSince(startedAt)
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
        elapsed = 0
        startedAt = nil
        stream = nil
        legacyWriter = nil
        destinationURL = nil
        nativeObjects.removeAll()
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

/// AVFoundation fallback used on macOS 13–14. The stream is owned by `ScreenRecorder`; this
/// object only serializes sample delivery and finalization for one MP4 file.
private final class LegacyRecordingWriter: NSObject, SCStreamOutput, @unchecked Sendable {
    let sampleQueue = DispatchQueue(label: "io.notable.recording.samples")

    private let writer: AVAssetWriter
    private let videoInput: AVAssetWriterInput
    private let audioInput: AVAssetWriterInput
    private var sessionStarted = false
    private var hasFinished = false

    init(url: URL, videoSize: CGSize) throws {
        writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        videoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: Int(videoSize.width.rounded()),
                AVVideoHeightKey: Int(videoSize.height.rounded()),
                AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 12_000_000],
            ]
        )
        audioInput = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 48_000,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 160_000,
            ]
        )
        videoInput.expectsMediaDataInRealTime = true
        audioInput.expectsMediaDataInRealTime = true
        guard writer.canAdd(videoInput), writer.canAdd(audioInput) else {
            throw NSError(domain: "io.notable.recording", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "The MP4 writer could not accept its media inputs.",
            ])
        }
        writer.add(videoInput)
        writer.add(audioInput)
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard sampleBuffer.isValid, CMSampleBufferDataIsReady(sampleBuffer) else { return }
        sampleQueue.async { [weak self] in self?.append(sampleBuffer, type: type) }
    }

    func finish() async {
        await withCheckedContinuation { continuation in
            sampleQueue.async { [weak self] in
                guard let self, !self.hasFinished else {
                    continuation.resume()
                    return
                }
                self.hasFinished = true
                self.videoInput.markAsFinished()
                self.audioInput.markAsFinished()
                guard self.sessionStarted else {
                    self.writer.cancelWriting()
                    continuation.resume()
                    return
                }
                self.writer.finishWriting { continuation.resume() }
            }
        }
    }

    private func append(_ sampleBuffer: CMSampleBuffer, type: SCStreamOutputType) {
        guard !hasFinished else { return }
        switch type {
        case .screen:
            if !sessionStarted {
                writer.startWriting()
                writer.startSession(atSourceTime: sampleBuffer.presentationTimeStamp)
                sessionStarted = true
            }
            if videoInput.isReadyForMoreMediaData { videoInput.append(sampleBuffer) }
        case .audio:
            guard sessionStarted else { return }
            if audioInput.isReadyForMoreMediaData { audioInput.append(sampleBuffer) }
        default:
            break
        }
    }
}
