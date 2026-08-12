import AppKit
import CoreGraphics

/// Samples surrounding Capture pixels to fill erase-mode Censors locally.
enum CensorEraseSampler {
    static func averageSurroundingColor(
        in rect: CGRect,
        image: CGImage,
        pointSize: CGSize? = nil
    ) -> RGBAColor? {
        let r = rect.standardized
        guard r.width > 0, r.height > 0 else { return nil }

        let width = image.width
        let height = image.height
        let pointSize = pointSize ?? CGSize(width: width, height: height)
        guard pointSize.width > 0, pointSize.height > 0 else { return nil }
        guard let data = image.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return nil }

        let bytesPerPixel = image.bitsPerPixel / 8
        let bytesPerRow = image.bytesPerRow
        guard bytesPerPixel >= 4 else { return nil }

        var sumR = 0.0, sumG = 0.0, sumB = 0.0
        var count = 0

        func sample(x: Int, y: Int) {
            guard x >= 0, y >= 0, x < width, y < height else { return }
            let offset = y * bytesPerRow + x * bytesPerPixel
            let r8 = Double(ptr[offset])
            let g8 = Double(ptr[offset + 1])
            let b8 = Double(ptr[offset + 2])
            sumR += r8 / 255
            sumG += g8 / 255
            sumB += b8 / 255
            count += 1
        }

        let scaleX = CGFloat(width) / pointSize.width
        let scaleY = CGFloat(height) / pointSize.height
        let minX = Int(floor(r.minX * scaleX))
        let maxX = Int(ceil(r.maxX * scaleX))
        let minY = Int(floor(r.minY * scaleY))
        let maxY = Int(ceil(r.maxY * scaleY))
        guard minX < maxX, minY < maxY else { return nil }

        for x in (minX - 1)...maxX {
            sample(x: x, y: minY - 1)
            sample(x: x, y: maxY)
        }
        for y in minY..<maxY {
            sample(x: minX - 1, y: y)
            sample(x: maxX, y: y)
        }

        guard count > 0 else { return nil }
        return RGBAColor(
            red: sumR / Double(count),
            green: sumG / Double(count),
            blue: sumB / Double(count)
        )
    }
}
