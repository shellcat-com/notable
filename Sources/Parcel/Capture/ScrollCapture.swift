import CoreGraphics
import Foundation
import Vision

/// A user-guided scrolling Capture. The user chooses the scrolling region once, scrolls the
/// source app, then adds frames from the menu bar. Every frame is recaptured with
/// ScreenCaptureKit and stitched locally; no image data leaves the Mac.
@MainActor
final class ScrollCaptureSession {

    enum Error: LocalizedError {
        case displayUnavailable
        case cropFailed
        case noOverlap

        var errorDescription: String? {
            switch self {
            case .displayUnavailable: return "The selected display is no longer available."
            case .cropFailed: return "The scrolling Selection could not be captured."
            case .noOverlap: return "No reliable overlap was found. Scroll by a smaller amount and add another frame."
            }
        }
    }

    private let engine = CaptureEngine()
    private let selectionRect: CGRect
    private let displayID: CGDirectDisplayID
    private var lastFrame: Capture
    private var stitched: Capture

    private(set) var frameCount = 1

    init(selection: SelectionResult, initialCapture: Capture) {
        selectionRect = selection.rectInPoints
        displayID = selection.screen.id
        lastFrame = initialCapture
        stitched = initialCapture
    }

    func appendCurrentFrame() async throws {
        let frozen = try await engine.freezeScreens()
        guard let screen = frozen.first(where: { $0.id == displayID }) else {
            throw Error.displayUnavailable
        }
        let selection = SelectionResult(screen: screen, rectInPoints: selectionRect)
        guard let next = engine.makeCapture(from: selection) else { throw Error.cropFailed }
        let previousImage = lastFrame.image
        let nextImage = next.image
        guard let image = try await Task.detached(priority: .userInitiated, operation: {
            try ScrollCaptureStitcher.append(upper: previousImage, lower: nextImage)
        }).value else {
            throw Error.noOverlap
        }
        stitched = Capture(image: image, scale: stitched.scale)
        lastFrame = next
        frameCount += 1
    }

    func finish() -> Capture { stitched }
}

/// Uses Vision for a likely translation, then validates the overlap directly against sampled
/// pixels before compositing. Vision gets us to the right neighbourhood; pixel scoring rejects
/// weak registrations on repeated or static page regions.
enum ScrollCaptureStitcher {

    static func append(upper: CGImage, lower: CGImage) throws -> CGImage? {
        // Prefer vertical stitch; fall back to horizontal for sideways scrolling content.
        if upper.width == lower.width, upper.height == lower.height {
            let expected = visionExpectedOverlap(upper: upper, lower: lower, horizontal: false)
            if let overlap = PixelOverlapFinder.bestOverlap(upper: upper, lower: lower, expected: expected, horizontal: false) {
                return verticallyStack(upper: upper, lower: lower, overlap: overlap)
            }
            let expectedH = visionExpectedOverlap(upper: upper, lower: lower, horizontal: true)
            if let overlap = PixelOverlapFinder.bestOverlap(upper: upper, lower: lower, expected: expectedH, horizontal: true) {
                return horizontallyStack(left: upper, right: lower, overlap: overlap)
            }
            return nil
        }
        return nil
    }

    private static func visionExpectedOverlap(upper: CGImage, lower: CGImage, horizontal: Bool) -> Int? {
        let request = VNTranslationalImageRegistrationRequest(targetedCGImage: upper)
        let handler = VNImageRequestHandler(cgImage: lower, orientation: .up)
        do {
            try handler.perform([request])
            guard let transform = request.results?.first?.alignmentTransform else { return nil }
            if horizontal {
                let shift = abs(Int(transform.tx.rounded()))
                let overlap = lower.width - shift
                return (16..<lower.width).contains(overlap) ? overlap : nil
            } else {
                let shift = abs(Int(transform.ty.rounded()))
                let overlap = lower.height - shift
                return (16..<lower.height).contains(overlap) ? overlap : nil
            }
        } catch {
            return nil
        }
    }

    private static func verticallyStack(upper: CGImage, lower: CGImage, overlap: Int) -> CGImage? {
        let width = upper.width
        let height = upper.height + lower.height - overlap
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        context.draw(upper, in: CGRect(x: 0, y: 0, width: width, height: upper.height))
        context.draw(
            lower,
            in: CGRect(x: 0, y: upper.height - overlap, width: width, height: lower.height)
        )
        return context.makeImage()
    }

    private static func horizontallyStack(left: CGImage, right: CGImage, overlap: Int) -> CGImage? {
        let height = left.height
        let width = left.width + right.width - overlap
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        context.draw(left, in: CGRect(x: 0, y: 0, width: left.width, height: height))
        context.draw(
            right,
            in: CGRect(x: left.width - overlap, y: 0, width: right.width, height: height)
        )
        return context.makeImage()
    }
}

private enum PixelOverlapFinder {

    /// Finds the best overlap for vertical or horizontal stitching.
    static func bestOverlap(upper: CGImage, lower: CGImage, expected: Int?, horizontal: Bool) -> Int? {
        guard let a = PixelGrid(image: upper), let b = PixelGrid(image: lower),
              a.width == b.width, a.height == b.height else { return nil }

        let axis = horizontal ? a.width : a.height
        let minimum = max(24, axis / 50)
        let maximum = axis - 4
        guard minimum < maximum else { return nil }
        var candidates = Set(stride(from: minimum, through: maximum, by: 8))
        if let expected {
            let lowerBound = max(minimum, expected - 100)
            let upperBound = min(maximum, expected + 100)
            candidates.formUnion(stride(from: lowerBound, through: upperBound, by: 2))
        }

        var best: (overlap: Int, score: Double)?
        for overlap in candidates {
            let score = horizontal
                ? a.horizontalDifference(to: b, overlap: overlap)
                : a.difference(to: b, overlap: overlap)
            if best == nil || score < best!.score { best = (overlap, score) }
        }
        guard let best, best.score < 22 else { return nil }
        return best.overlap
    }
}

private struct PixelGrid {
    let width: Int
    let height: Int
    let bytes: [UInt8]

    init?(image: CGImage) {
        // 96 columns keeps matching quick even for 5K Captures while preserving the exact row
        // count so any resulting overlap maps 1:1 back to source pixels.
        let gridWidth = min(image.width, 96)
        let gridHeight = image.height
        guard gridWidth > 0, gridHeight > 0 else { return nil }
        var pixels = [UInt8](repeating: 0, count: gridWidth * gridHeight * 4)
        let rendered = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: gridWidth,
                height: gridHeight,
                bitsPerComponent: 8,
                bytesPerRow: gridWidth * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            ) else { return false }
            context.interpolationQuality = .low
            context.draw(image, in: CGRect(x: 0, y: 0, width: gridWidth, height: gridHeight))
            return true
        }
        guard rendered else { return nil }
        width = gridWidth
        height = gridHeight
        bytes = pixels
    }

    func difference(to other: PixelGrid, overlap: Int) -> Double {
        let rowSamples = min(14, max(overlap / 20, 4))
        let columnStep = max(1, width / 32)
        var total = 0
        var count = 0
        for sample in 0..<rowSamples {
            let offset = (sample + 1) * overlap / (rowSamples + 1)
            let upperRow = height - overlap + offset
            let lowerRow = offset
            for column in stride(from: 0, to: width, by: columnStep) {
                let upperIndex = (upperRow * width + column) * 4
                let lowerIndex = (lowerRow * width + column) * 4
                total += abs(Int(bytes[upperIndex]) - Int(other.bytes[lowerIndex]))
                total += abs(Int(bytes[upperIndex + 1]) - Int(other.bytes[lowerIndex + 1]))
                total += abs(Int(bytes[upperIndex + 2]) - Int(other.bytes[lowerIndex + 2]))
                count += 3
            }
        }
        return count > 0 ? Double(total) / Double(count) : .greatestFiniteMagnitude
    }

    func horizontalDifference(to other: PixelGrid, overlap: Int) -> Double {
        let columnSamples = min(14, max(overlap / 20, 4))
        let rowStep = max(1, height / 32)
        var total = 0
        var count = 0
        for sample in 0..<columnSamples {
            let offset = (sample + 1) * overlap / (columnSamples + 1)
            let leftCol = width - overlap + offset
            let rightCol = offset
            for row in stride(from: 0, to: height, by: rowStep) {
                let leftIndex = (row * width + leftCol) * 4
                let rightIndex = (row * width + rightCol) * 4
                total += abs(Int(bytes[leftIndex]) - Int(other.bytes[rightIndex]))
                total += abs(Int(bytes[leftIndex + 1]) - Int(other.bytes[rightIndex + 1]))
                total += abs(Int(bytes[leftIndex + 2]) - Int(other.bytes[rightIndex + 2]))
                count += 3
            }
        }
        return count > 0 ? Double(total) / Double(count) : .greatestFiniteMagnitude
    }
}
