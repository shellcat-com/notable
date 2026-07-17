import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins

/// Renders the adjusted base Capture and the Censor sources (blur / pixelate) that DERIVE from
/// the adjusted image, so a brightened/warmed Capture keeps its censored patches tonally
/// consistent — on screen and on export.
///
/// Thread-safe: all inputs are immutable and `CIContext.createCGImage` supports concurrent use,
/// so methods are callable from the background render queue. On-device Core Image only.
final class CaptureAdjuster {

    private let sourceImage: CIImage
    private let sourceExtent: CGRect
    private let sourceColorSpace: CGColorSpace?
    /// Raw capture pixels; the neutral short-circuit and every failure path return this.
    private let fallback: CGImage
    private let context = CIContext(options: [.cacheIntermediates: false])
    private let blurSigma: Double
    private let pixellateScale: Double

    init(capture: Capture) {
        fallback = capture.image
        sourceImage = CIImage(cgImage: capture.image)
        sourceExtent = sourceImage.extent
        sourceColorSpace = capture.image.colorSpace
        let minSide = Double(min(sourceExtent.width, sourceExtent.height))
        blurSigma = max(8, minSide / 90)
        pixellateScale = max(8, minSide / 60)
    }

    // MARK: Outputs

    /// The Capture with `adjustments` applied. Pixel dimensions always equal the raw Capture's.
    func makeAdjusted(_ adjustments: Adjustments) -> CGImage {
        guard !adjustments.isNeutral else { return fallback }
        let output = apply(adjustments, to: sourceImage)
        return createCGImage(output, preserveColorSpace: true)
    }

    /// Gaussian blur OF the adjusted image (Censor `.blur` source).
    func makeBlurred(_ adjustments: Adjustments) -> CGImage {
        let adjusted = adjustments.isNeutral ? sourceImage : apply(adjustments, to: sourceImage)
        let blurred = adjusted
            .clampedToExtent()
            .applyingGaussianBlur(sigma: blurSigma)
            .cropped(to: sourceExtent)
        return createCGImage(blurred, preserveColorSpace: false)
    }

    /// Mosaic OF the adjusted image (Censor `.pixelate` source).
    func makePixelated(_ adjustments: Adjustments) -> CGImage {
        let adjusted = adjustments.isNeutral ? sourceImage : apply(adjustments, to: sourceImage)
        let filter = CIFilter.pixellate()
        filter.inputImage = adjusted.clampedToExtent()
        filter.scale = Float(pixellateScale)
        filter.center = CGPoint(x: sourceExtent.midX, y: sourceExtent.midY)
        let output = (filter.outputImage ?? adjusted).cropped(to: sourceExtent)
        return createCGImage(output, preserveColorSpace: false)
    }

    // MARK: Chain

    /// CIColorControls → CIVibrance → CITemperatureAndTint → CISharpenLuminance, skipping any
    /// filter at its neutral value. Clamps + crops around sharpen so pixel dims never change.
    private func apply(_ adj: Adjustments, to image: CIImage) -> CIImage {
        var img = image

        if adj.brightness != 0 || adj.contrast != 1 || adj.saturation != 1 {
            let filter = CIFilter.colorControls()
            filter.inputImage = img
            filter.brightness = Float(adj.brightness)
            filter.contrast = Float(adj.contrast)
            filter.saturation = Float(adj.saturation)
            img = filter.outputImage ?? img
        }
        if adj.vibrance != 0 {
            let filter = CIFilter.vibrance()
            filter.inputImage = img
            filter.amount = Float(adj.vibrance)
            img = filter.outputImage ?? img
        }
        if adj.temperature != 0 || adj.tint != 0 {
            let filter = CIFilter.temperatureAndTint()
            filter.inputImage = img
            filter.neutral = CIVector(x: 6500, y: 0)
            // +temperature → warmer (neutral gray mapped to a warmer white warms the image).
            filter.targetNeutral = CIVector(x: 6500 + adj.temperature * 30, y: adj.tint)
            img = filter.outputImage ?? img
        }
        if adj.sharpness > 0 {
            let filter = CIFilter.sharpenLuminance()
            filter.inputImage = img.clampedToExtent()
            filter.sharpness = Float(adj.sharpness)
            img = (filter.outputImage ?? img).cropped(to: sourceExtent)
        }
        return img
    }

    private func createCGImage(_ image: CIImage, preserveColorSpace: Bool) -> CGImage {
        if preserveColorSpace, let space = sourceColorSpace {
            return context.createCGImage(image, from: sourceExtent, format: .RGBA8, colorSpace: space)
                ?? fallback
        }
        return context.createCGImage(image, from: sourceExtent) ?? fallback
    }
}
