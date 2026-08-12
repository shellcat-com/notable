#!/usr/bin/env swift
/**
 Smoke-tests the recording writer finalize contract with deterministic synthetic media:
 PixelBufferAdaptor video + deferred AAC audio -> playable MP4 with moov.
 */
import AVFoundation
import CoreMedia
import CoreVideo
import Foundation

enum SmokeSampleType {
    case screen
    case audio
}

final class SmokeWriter: @unchecked Sendable {
    let queue = DispatchQueue(label: "smoke.recording")
    private let writer: AVAssetWriter
    private let videoInput: AVAssetWriterInput
    private let adaptor: AVAssetWriterInputPixelBufferAdaptor
    private var audioInput: AVAssetWriterInput?
    private var sessionStarted = false
    private var hasFinished = false
    private var videoCount = 0
    private var pendingVideo: [CMSampleBuffer] = []
    private var pendingAudio: [CMSampleBuffer] = []
    private var sawAudio = false

    init(url: URL, size: CGSize) throws {
        writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        videoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: Int(size.width),
                AVVideoHeightKey: Int(size.height),
                AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 6_000_000],
            ]
        )
        videoInput.expectsMediaDataInRealTime = true
        adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: Int(size.width),
                kCVPixelBufferHeightKey as String: Int(size.height),
            ]
        )
        guard writer.canAdd(videoInput) else { throw NSError(domain: "smoke", code: 1) }
        writer.add(videoInput)
    }

    func receive(_ sampleBuffer: CMSampleBuffer, type: SmokeSampleType) {
        guard sampleBuffer.isValid, CMSampleBufferDataIsReady(sampleBuffer) else { return }
        queue.async { self.append(sampleBuffer, type: type) }
    }

    private func append(_ sampleBuffer: CMSampleBuffer, type: SmokeSampleType) {
        guard !hasFinished else { return }
        switch type {
        case .screen:
            if !sessionStarted {
                pendingVideo.append(sampleBuffer)
                _ = start(force: pendingVideo.count >= 12)
                return
            }
            appendVideo(sampleBuffer)
        case .audio:
            if !sessionStarted {
                sawAudio = true
                pendingAudio.append(sampleBuffer)
                _ = start(force: false)
                return
            }
            appendAudio(sampleBuffer)
        }
    }

    private func start(force: Bool) -> Bool {
        guard !sessionStarted, let first = pendingVideo.first else { return false }
        if !force && !sawAudio { return false }
        if sawAudio {
            let input = AVAssetWriterInput(
                mediaType: .audio,
                outputSettings: [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: 48_000,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderBitRateKey: 128_000,
                ]
            )
            input.expectsMediaDataInRealTime = true
            if writer.canAdd(input) {
                writer.add(input)
                audioInput = input
            }
        }
        guard writer.startWriting() else { return false }
        writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(first))
        sessionStarted = true
        let videos = pendingVideo
        let audios = pendingAudio
        pendingVideo.removeAll()
        pendingAudio.removeAll()
        videos.forEach(appendVideo)
        audios.forEach(appendAudio)
        return true
    }

    private func appendVideo(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              writer.status == .writing,
              videoInput.isReadyForMoreMediaData
        else { return }
        if adaptor.append(pixelBuffer, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) {
            videoCount += 1
        }
    }

    private func appendAudio(_ sampleBuffer: CMSampleBuffer) {
        guard let audioInput, writer.status == .writing, audioInput.isReadyForMoreMediaData else { return }
        _ = audioInput.append(sampleBuffer)
    }

    func finish() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.async {
                self.hasFinished = true
                if !self.sessionStarted { _ = self.start(force: true) }
                guard self.sessionStarted, self.videoCount > 0 else {
                    self.writer.cancelWriting()
                    cont.resume(throwing: NSError(domain: "smoke", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "no video frames",
                    ]))
                    return
                }
                self.videoInput.markAsFinished()
                self.audioInput?.markAsFinished()
                self.writer.finishWriting {
                    if self.writer.status == .completed {
                        cont.resume()
                    } else {
                        cont.resume(throwing: self.writer.error ?? NSError(domain: "smoke", code: 3))
                    }
                }
            }
        }
    }
}

let out = URL(fileURLWithPath: "/tmp/parcel-smoke-recording-finalize.mp4")
try? FileManager.default.removeItem(at: out)

func makeVideoSampleBuffer(width: Int, height: Int, frame: Int) throws -> CMSampleBuffer {
    var pixelBuffer: CVPixelBuffer?
    let attributes: [String: Any] = [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
        kCVPixelBufferWidthKey as String: width,
        kCVPixelBufferHeightKey as String: height,
        kCVPixelBufferCGImageCompatibilityKey as String: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
    ]
    let pixelStatus = CVPixelBufferCreate(
        kCFAllocatorDefault,
        width,
        height,
        kCVPixelFormatType_32BGRA,
        attributes as CFDictionary,
        &pixelBuffer
    )
    guard pixelStatus == kCVReturnSuccess, let pixelBuffer else {
        throw NSError(domain: "smoke", code: Int(pixelStatus), userInfo: [
            NSLocalizedDescriptionKey: "Could not create video pixel buffer.",
        ])
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
    guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
        throw NSError(domain: "smoke", code: 4, userInfo: [
            NSLocalizedDescriptionKey: "Could not lock video pixel buffer.",
        ])
    }
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let bytes = baseAddress.assumingMemoryBound(to: UInt8.self)
    for y in 0..<height {
        for x in 0..<width {
            let offset = y * bytesPerRow + x * 4
            bytes[offset] = UInt8((frame * 11 + x) % 256)
            bytes[offset + 1] = UInt8((frame * 7 + y) % 256)
            bytes[offset + 2] = UInt8((x + y + frame) % 256)
            bytes[offset + 3] = 255
        }
    }

    var formatDescription: CMVideoFormatDescription?
    let formatStatus = CMVideoFormatDescriptionCreateForImageBuffer(
        allocator: kCFAllocatorDefault,
        imageBuffer: pixelBuffer,
        formatDescriptionOut: &formatDescription
    )
    guard formatStatus == noErr, let formatDescription else {
        throw NSError(domain: "smoke", code: Int(formatStatus), userInfo: [
            NSLocalizedDescriptionKey: "Could not create video format description.",
        ])
    }

    var timing = CMSampleTimingInfo(
        duration: CMTime(value: 1, timescale: 30),
        presentationTimeStamp: CMTime(value: CMTimeValue(frame), timescale: 30),
        decodeTimeStamp: .invalid
    )
    var sampleBuffer: CMSampleBuffer?
    let sampleStatus = CMSampleBufferCreateReadyWithImageBuffer(
        allocator: kCFAllocatorDefault,
        imageBuffer: pixelBuffer,
        formatDescription: formatDescription,
        sampleTiming: &timing,
        sampleBufferOut: &sampleBuffer
    )
    guard sampleStatus == noErr, let sampleBuffer else {
        throw NSError(domain: "smoke", code: Int(sampleStatus), userInfo: [
            NSLocalizedDescriptionKey: "Could not create video sample buffer.",
        ])
    }
    return sampleBuffer
}

func makeSilentAudioSampleBuffer(startFrame: Int, frameCount: Int, channels: UInt32 = 2) throws -> CMSampleBuffer {
    let sampleRate: Double = 48_000
    let bytesPerSample = 2
    let bytesPerFrame = Int(channels) * bytesPerSample
    var asbd = AudioStreamBasicDescription(
        mSampleRate: sampleRate,
        mFormatID: kAudioFormatLinearPCM,
        mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
        mBytesPerPacket: UInt32(bytesPerFrame),
        mFramesPerPacket: 1,
        mBytesPerFrame: UInt32(bytesPerFrame),
        mChannelsPerFrame: channels,
        mBitsPerChannel: UInt32(bytesPerSample * 8),
        mReserved: 0
    )
    var formatDescription: CMAudioFormatDescription?
    let formatStatus = CMAudioFormatDescriptionCreate(
        allocator: kCFAllocatorDefault,
        asbd: &asbd,
        layoutSize: 0,
        layout: nil,
        magicCookieSize: 0,
        magicCookie: nil,
        extensions: nil,
        formatDescriptionOut: &formatDescription
    )
    guard formatStatus == noErr, let formatDescription else {
        throw NSError(domain: "smoke", code: Int(formatStatus), userInfo: [
            NSLocalizedDescriptionKey: "Could not create audio format description.",
        ])
    }

    let byteCount = frameCount * bytesPerFrame
    var blockBuffer: CMBlockBuffer?
    let blockStatus = CMBlockBufferCreateWithMemoryBlock(
        allocator: kCFAllocatorDefault,
        memoryBlock: nil,
        blockLength: byteCount,
        blockAllocator: kCFAllocatorDefault,
        customBlockSource: nil,
        offsetToData: 0,
        dataLength: byteCount,
        flags: 0,
        blockBufferOut: &blockBuffer
    )
    guard blockStatus == noErr, let blockBuffer else {
        throw NSError(domain: "smoke", code: Int(blockStatus), userInfo: [
            NSLocalizedDescriptionKey: "Could not create audio block buffer.",
        ])
    }
    var silence = [UInt8](repeating: 0, count: byteCount)
    let copyStatus = silence.withUnsafeBytes { rawBuffer in
        CMBlockBufferReplaceDataBytes(
            with: rawBuffer.baseAddress!,
            blockBuffer: blockBuffer,
            offsetIntoDestination: 0,
            dataLength: byteCount
        )
    }
    guard copyStatus == noErr else {
        throw NSError(domain: "smoke", code: Int(copyStatus), userInfo: [
            NSLocalizedDescriptionKey: "Could not fill audio block buffer.",
        ])
    }

    var timing = CMSampleTimingInfo(
        duration: CMTime(value: 1, timescale: CMTimeScale(sampleRate)),
        presentationTimeStamp: CMTime(value: CMTimeValue(startFrame), timescale: CMTimeScale(sampleRate)),
        decodeTimeStamp: .invalid
    )
    var sampleSize = bytesPerFrame
    var sampleBuffer: CMSampleBuffer?
    let sampleStatus = CMSampleBufferCreateReady(
        allocator: kCFAllocatorDefault,
        dataBuffer: blockBuffer,
        formatDescription: formatDescription,
        sampleCount: frameCount,
        sampleTimingEntryCount: 1,
        sampleTimingArray: &timing,
        sampleSizeEntryCount: 1,
        sampleSizeArray: &sampleSize,
        sampleBufferOut: &sampleBuffer
    )
    guard sampleStatus == noErr, let sampleBuffer else {
        throw NSError(domain: "smoke", code: Int(sampleStatus), userInfo: [
            NSLocalizedDescriptionKey: "Could not create audio sample buffer.",
        ])
    }
    return sampleBuffer
}

do {
    let width = 320
    let height = 180
    let writer = try SmokeWriter(url: out, size: CGSize(width: width, height: height))
    let audioChunkFrames = 4_800
    for chunk in 0..<30 {
        writer.receive(
            try makeSilentAudioSampleBuffer(startFrame: chunk * audioChunkFrames, frameCount: audioChunkFrames),
            type: .audio
        )
        for frameOffset in 0..<3 {
            writer.receive(
                try makeVideoSampleBuffer(width: width, height: height, frame: chunk * 3 + frameOffset),
                type: .screen
            )
        }
    }
    writer.queue.sync {}
    try await writer.finish()

    let asset = AVURLAsset(url: out)
    let videoTracks = try await asset.loadTracks(withMediaType: .video)
    let audioTracks = try await asset.loadTracks(withMediaType: .audio)
    let duration = try await asset.load(.duration)
    let data = try Data(contentsOf: out)
    let moov = data.range(of: Data([0x6d, 0x6f, 0x6f, 0x76]))?.lowerBound ?? -1
    guard !videoTracks.isEmpty, !audioTracks.isEmpty, duration.seconds > 0.5, moov >= 0 else {
        fputs(
            "FAIL: duration=\(duration.seconds) video=\(videoTracks.count) audio=\(audioTracks.count) moov=\(moov)\n",
            stderr
        )
        exit(1)
    }
    print(
        "PASS: \(out.path) duration=\(String(format: "%.2f", duration.seconds))s "
            + "video=\(videoTracks.count) audio=\(audioTracks.count) moov=\(moov) bytes=\(data.count)"
    )
} catch {
    fputs("FAIL: \(error)\n", stderr)
    exit(1)
}
