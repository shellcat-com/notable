import CoreGraphics

/// O(1) per-pixel reads over the Capture, for the Loupe readout and the Eyedropper.
///
/// Draws the image ONCE into an owned RGBX8/sRGB buffer, vertically flipped so buffer row 0 is
/// the TOP of the Capture (CGContext is bottom-left origin; the Capture's pixel origin is
/// top-left). RGBX with no premultiply keeps the hex readout exact for an opaque Capture.
/// Pure Core Graphics — entirely on-device.
final class CapturePixelSampler {

    let width: Int
    let height: Int
    private let bytesPerRow: Int
    private let data: UnsafeMutableRawPointer

    init?(cgImage: CGImage) {
        width = cgImage.width
        height = cgImage.height
        guard width > 0, height > 0 else { return nil }
        bytesPerRow = width * 4
        data = UnsafeMutableRawPointer.allocate(byteCount: height * bytesPerRow, alignment: 4)

        guard
            let space = CGColorSpace(name: CGColorSpace.sRGB),
            let context = CGContext(
                data: data,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: space,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            )
        else {
            data.deallocate()
            return nil
        }

        // Flip so buffer row 0 = top of the Capture.
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        context.interpolationQuality = .none
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    }

    deinit {
        data.deallocate()
    }

    /// Color at TOP-LEFT-origin pixel (x, y); nil if out of bounds. No allocation.
    func rgba(x: Int, y: Int) -> RGBAColor? {
        guard x >= 0, x < width, y >= 0, y < height else { return nil }
        let pixel = data.advanced(by: y * bytesPerRow + x * 4).assumingMemoryBound(to: UInt8.self)
        return RGBAColor(
            red: Double(pixel[0]) / 255,
            green: Double(pixel[1]) / 255,
            blue: Double(pixel[2]) / 255,
            alpha: 1
        )
    }
}
