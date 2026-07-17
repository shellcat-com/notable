import AppKit
import CoreGraphics
import CoreMedia
import ScreenCaptureKit

/// Grabs pixels from the screen via ScreenCaptureKit and turns a Selection into a Capture.
///
/// Freeze model: `freezeScreens()` captures a full-resolution image of every display up front;
/// `makeCapture(from:)` then crops from those frozen pixels — the screen the user selects from is
/// exactly what they saw when the Overlay appeared.
final class CaptureEngine {

    enum CaptureError: Error { case noDisplays, cropFailed }

    // MARK: Freeze

    /// Capture a full-resolution, frozen image of every online display, plus the on-screen
    /// window list for window-snap.
    @MainActor
    func freezeScreens() async throws -> [FrozenScreen] {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false, onScreenWindowsOnly: true
        )
        guard !content.displays.isEmpty else { throw CaptureError.noDisplays }

        var frozen: [FrozenScreen] = []
        for display in content.displays {
            guard let nsScreen = NSScreen.screen(forDisplayID: display.displayID) else { continue }
            let scale = nsScreen.backingScaleFactor
            let pointSize = nsScreen.frame.size
            let image = try await captureDisplayImage(display, pointSize: pointSize, scale: scale)
            let windows = snapWindows(for: display, allWindows: content.windows)
            frozen.append(
                FrozenScreen(
                    id: display.displayID,
                    screen: nsScreen,
                    image: image,
                    scale: scale,
                    pointSize: pointSize,
                    windows: windows
                )
            )
        }
        guard !frozen.isEmpty else { throw CaptureError.noDisplays }
        return frozen
    }

    private func captureDisplayImage(
        _ display: SCDisplay, pointSize: CGSize, scale: CGFloat
    ) async throws -> CGImage {
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.width = Int((pointSize.width * scale).rounded())
        config.height = Int((pointSize.height * scale).rounded())
        config.showsCursor = false
        config.scalesToFit = false

        if #available(macOS 14.0, *) {
            return try await SCScreenshotManager.captureImage(
                contentFilter: filter, configuration: config
            )
        } else {
            return try await SingleFrameStreamCapturer().capture(filter: filter, config: config)
        }
    }

    // MARK: Window snap

    /// Windows on this display, converted to local top-left point coordinates, filtered to the
    /// meaningful ones (skip our own windows, the desktop, and tiny slivers).
    private func snapWindows(for display: SCDisplay, allWindows: [SCWindow]) -> [SnapWindow] {
        let displayFrame = display.frame // global CG top-left points
        let ownBundleID = Bundle.main.bundleIdentifier

        return allWindows.compactMap { win -> SnapWindow? in
            guard win.isOnScreen else { return nil }
            guard win.frame.width >= 12, win.frame.height >= 12 else { return nil }
            guard win.frame.intersects(displayFrame) else { return nil }
            if let bid = win.owningApplication?.bundleIdentifier, bid == ownBundleID { return nil }

            let local = CGRect(
                x: win.frame.minX - displayFrame.minX,
                y: win.frame.minY - displayFrame.minY,
                width: win.frame.width,
                height: win.frame.height
            )
            return SnapWindow(
                id: Int(win.windowID),
                title: win.title ?? "",
                appName: win.owningApplication?.applicationName ?? "",
                frameInScreen: local
            )
        }
    }

    // MARK: Crop

    /// Crop the frozen pixels to the user's Selection.
    func makeCapture(from result: SelectionResult) -> Capture? {
        let scale = result.screen.scale
        let src = result.rectInPoints
        var pixelRect = CGRect(
            x: src.minX * scale,
            y: src.minY * scale,
            width: src.width * scale,
            height: src.height * scale
        ).integral

        // Clamp to image bounds so an edge drag can't ask for out-of-range pixels.
        let bounds = CGRect(x: 0, y: 0, width: result.screen.image.width, height: result.screen.image.height)
        pixelRect = pixelRect.intersection(bounds)
        guard pixelRect.width >= 1, pixelRect.height >= 1 else { return nil }
        guard let cropped = result.screen.image.cropping(to: pixelRect) else { return nil }
        return Capture(image: cropped, scale: scale)
    }

    /// Combines all frozen displays into one Capture in their actual desktop arrangement. Mixed
    /// density displays are normalized to the highest connected backing scale so no source image
    /// is upscaled below its Capture-point dimensions.
    func makeStitchedCapture(from screens: [FrozenScreen]) -> Capture? {
        guard !screens.isEmpty else { return nil }
        let desktop = screens.map { $0.screen.frame }.reduce(screens[0].screen.frame) { $0.union($1) }
        let scale = screens.map(\.scale).max() ?? 1
        let width = Int((desktop.width * scale).rounded(.up))
        let height = Int((desktop.height * scale).rounded(.up))
        guard width > 0, height > 0,
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return nil }

        context.setFillColor(NSColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        // Convert Core Graphics' bottom-left coordinates to the Canvas' top-left Capture space.
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: scale, y: -scale)

        for frozen in screens {
            let frame = frozen.screen.frame
            let rect = CGRect(
                x: frame.minX - desktop.minX,
                y: desktop.maxY - frame.maxY,
                width: frame.width,
                height: frame.height
            )
            context.interpolationQuality = .high
            context.draw(frozen.image, in: rect)
        }
        guard let image = context.makeImage() else { return nil }
        return Capture(image: image, scale: scale)
    }
}

// MARK: - macOS 13 fallback: single-frame SCStream capture

/// Grabs exactly one frame from an `SCStream`, converts it to a `CGImage`, and tears the stream
/// down. Used only on macOS 13 where `SCScreenshotManager` is unavailable. Untested on the current
/// dev machine (macOS 26 always takes the `SCScreenshotManager` path).
private final class SingleFrameStreamCapturer: NSObject, SCStreamOutput, @unchecked Sendable {
    private var continuation: CheckedContinuation<CGImage, Error>?
    private var stream: SCStream?
    private let lock = NSLock()
    private var finished = false
    private let sampleQueue = DispatchQueue(label: "io.notable.capture.singleframe")
    private let ciContext = CIContext()

    func capture(filter: SCContentFilter, config: SCStreamConfiguration) async throws -> CGImage {
        try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            do {
                let stream = SCStream(filter: filter, configuration: config, delegate: nil)
                try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: sampleQueue)
                self.stream = stream
                stream.startCapture { [weak self] error in
                    if let error { self?.finish(.failure(error)) }
                }
            } catch {
                self.continuation = nil
                cont.resume(throwing: error)
            }
        }
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, sampleBuffer.isValid else { return }
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cg = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
        finish(.success(cg))
    }

    private func finish(_ result: Result<CGImage, Error>) {
        lock.lock()
        guard !finished else { lock.unlock(); return }
        finished = true
        let cont = continuation
        continuation = nil
        let stream = self.stream
        self.stream = nil
        lock.unlock()

        stream?.stopCapture { _ in }
        switch result {
        case .success(let img): cont?.resume(returning: img)
        case .failure(let err): cont?.resume(throwing: err)
        }
    }
}
