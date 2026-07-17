import AppKit
import AVFoundation
import AVKit
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class RecordingWindowController: NSObject, NSWindowDelegate {
    var onClose: (() -> Void)?

    private let window: NSWindow

    init(url: URL) {
        let model = RecordingEditorModel(url: url)
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 860, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init()
        window.title = "Recording"
        window.minSize = NSSize(width: 600, height: 440)
        window.tabbingMode = .disallowed
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = NSHostingView(rootView: RecordingEditorView(model: model, onClose: { [weak self] in
            self?.window.close()
        }))
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }
}

@MainActor
private final class RecordingEditorModel: ObservableObject {
    let sourceURL: URL
    let player: AVPlayer

    @Published private(set) var duration: Double = 0
    @Published var startTime: Double = 0 { didSet { normalizeRange(changedStart: true) } }
    @Published var endTime: Double = 0 { didSet { normalizeRange(changedStart: false) } }
    @Published private(set) var isExporting = false
    @Published var errorMessage: String?

    private let asset: AVURLAsset
    private let minimumDuration = 0.1

    init(url: URL) {
        sourceURL = url
        asset = AVURLAsset(url: url)
        player = AVPlayer(url: url)
        let seconds = asset.duration.seconds
        duration = seconds.isFinite && seconds > 0 ? seconds : 0
        endTime = duration
    }

    var trimmedDuration: Double { max(endTime - startTime, 0) }

    func exportMP4() {
        savePanel(name: defaultName(extension: "mp4"), type: .mpeg4Movie) { [weak self] url in
            guard let self else { return }
            Task { await self.writeMP4(to: url) }
        }
    }

    func exportGIF() {
        savePanel(name: defaultName(extension: "gif"), type: .gif) { [weak self] url in
            guard let self else { return }
            Task { await self.writeGIF(to: url) }
        }
    }

    private func savePanel(name: String, type: UTType, completion: @escaping (URL) -> Void) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [type]
        panel.nameFieldStringValue = name
        panel.canCreateDirectories = true
        panel.begin { response in
            if response == .OK, let url = panel.url { completion(url) }
        }
    }

    private func writeMP4(to url: URL) async {
        isExporting = true
        errorMessage = nil
        defer { isExporting = false }
        do {
            guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
                throw ExportError.unavailable
            }
            exporter.outputURL = url
            exporter.outputFileType = .mp4
            exporter.timeRange = timeRange
            try await exporter.export(to: url, as: .mp4)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func writeGIF(to url: URL) async {
        isExporting = true
        errorMessage = nil
        defer { isExporting = false }
        let range = timeRange
        do {
            try await Task.detached(priority: .userInitiated) { [asset] in
                try RecordingGIFExporter.write(asset: asset, timeRange: range, to: url)
            }.value
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var timeRange: CMTimeRange {
        CMTimeRange(
            start: CMTime(seconds: startTime, preferredTimescale: 600),
            duration: CMTime(seconds: trimmedDuration, preferredTimescale: 600)
        )
    }

    private func normalizeRange(changedStart: Bool) {
        guard duration > 0 else { return }
        if changedStart {
            startTime = min(max(startTime, 0), max(endTime - minimumDuration, 0))
        } else {
            endTime = max(min(endTime, duration), min(startTime + minimumDuration, duration))
        }
        player.seek(to: CMTime(seconds: startTime, preferredTimescale: 600))
    }

    private func defaultName(extension fileExtension: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return "Parcel Recording \(formatter.string(from: Date())).\(fileExtension)"
    }

    private enum ExportError: LocalizedError {
        case unavailable
        var errorDescription: String? { "This recording cannot be exported on this Mac." }
    }
}

private struct RecordingEditorView: View {
    @ObservedObject var model: RecordingEditorModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VideoPlayer(player: model.player)
                .background(Color.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            controls
        }
        .frame(minWidth: 600, minHeight: 440)
        .onAppear { model.player.play() }
        .onDisappear { model.player.pause() }
        .alert("Export Failed", isPresented: errorPresented) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "Unknown error")
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Trim").font(.headline)
                Spacer()
                Text("\(time(model.startTime)) – \(time(model.endTime))")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 4) {
                Slider(value: $model.startTime, in: 0...max(model.endTime - 0.1, 0))
                    .help("Trim start")
                Slider(value: $model.endTime, in: min(model.startTime + 0.1, model.duration)...max(model.duration, 0.1))
                    .help("Trim end")
            }

            HStack {
                Text("\(time(model.trimmedDuration)) selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if model.isExporting { ProgressView().controlSize(.small) }
                Button("Export GIF") { model.exportGIF() }
                    .disabled(model.trimmedDuration <= 0 || model.isExporting)
                Button("Export MP4") { model.exportMP4() }
                    .disabled(model.trimmedDuration <= 0 || model.isExporting)
                Button(action: onClose) { Image(systemName: "xmark") }
                    .help("Close")
            }
        }
        .padding(14)
    }

    private var errorPresented: Binding<Bool> {
        Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })
    }

    private func time(_ seconds: Double) -> String {
        let total = max(Int(seconds.rounded(.down)), 0)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

private enum RecordingGIFExporter {
    static func write(asset: AVAsset, timeRange: CMTimeRange, to url: URL) throws {
        let duration = CMTimeGetSeconds(timeRange.duration)
        guard duration.isFinite, duration > 0 else { throw GIFError.emptyRange }
        let frameRate = 15.0
        let frameCount = max(1, Int(ceil(duration * frameRate)))
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.gif.identifier as CFString, frameCount, nil
        ) else { throw GIFError.destination }

        CGImageDestinationSetProperties(destination, [
            kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0],
        ] as CFDictionary)

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let frameProperties = [
            kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1 / frameRate],
        ] as CFDictionary

        for index in 0..<frameCount {
            let seconds = CMTimeGetSeconds(timeRange.start) + Double(index) / frameRate
            let time = CMTime(seconds: seconds, preferredTimescale: 600)
            let image = try generator.copyCGImage(at: time, actualTime: nil)
            CGImageDestinationAddImage(destination, image, frameProperties)
        }
        guard CGImageDestinationFinalize(destination) else { throw GIFError.finalize }
    }

    private enum GIFError: LocalizedError {
        case emptyRange, destination, finalize
        var errorDescription: String? {
            switch self {
            case .emptyRange: return "Choose a non-empty trim range."
            case .destination: return "The GIF destination could not be created."
            case .finalize: return "The GIF could not be finalized."
            }
        }
    }
}
