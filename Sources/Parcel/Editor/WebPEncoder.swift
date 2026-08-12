import CoreGraphics
import Foundation
import WebP

enum ParcelWebPEncoder {
    static func encode(_ image: CGImage, quality: Float = 92) -> Data? {
        guard let rgba = rgbaBytes(from: image) else { return nil }
        do {
            let encoded = try WebP(width: rgba.width, height: rgba.height, rgba: [UInt8](rgba.data))
                .encode(quality: quality)
            return Data(encoded)
        } catch {
            NSLog("Parcel: failed to encode WEBP — \(error)")
            return nil
        }
    }

    private static func rgbaBytes(from image: CGImage) -> (data: Data, width: Int, height: Int, bytesPerRow: Int)? {
        let width = image.width
        let height = image.height
        let bytesPerRow = width * 4
        var data = Data(count: bytesPerRow * height)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue

        let rendered = data.withUnsafeMutableBytes { buffer -> Bool in
            guard let base = buffer.baseAddress,
                  let context = CGContext(
                    data: base,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo
                  )
            else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return rendered ? (data, width, height, bytesPerRow) : nil
    }
}
