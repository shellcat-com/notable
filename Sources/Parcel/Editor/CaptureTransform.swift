import AppKit
import CoreGraphics
import CoreImage

/// Document-level Capture transforms (crop / resize / rotate / flip / expand / combine).
/// Remaps Annotation geometry in Capture-point space so the Phase 2 render pipeline stays valid.
enum CaptureTransform {

    static func crop(_ capture: Capture, toPoints rect: CGRect) -> Capture? {
        let scale = capture.scale
        var pixelRect = CGRect(
            x: rect.minX * scale,
            y: rect.minY * scale,
            width: rect.width * scale,
            height: rect.height * scale
        ).integral
        let bounds = CGRect(x: 0, y: 0, width: capture.image.width, height: capture.image.height)
        pixelRect = pixelRect.intersection(bounds)
        guard pixelRect.width >= 1, pixelRect.height >= 1,
              let cropped = capture.image.cropping(to: pixelRect)
        else { return nil }
        return Capture(image: cropped, scale: scale)
    }

    static func resize(_ capture: Capture, toPointSize size: CGSize) -> Capture? {
        let width = max(1, Int((size.width * capture.scale).rounded()))
        let height = max(1, Int((size.height * capture.scale).rounded()))
        guard let image = redraw(capture.image, width: width, height: height) else { return nil }
        return Capture(image: image, scale: capture.scale)
    }

    static func rotate90CW(_ capture: Capture) -> Capture? {
        guard let image = rotate(capture.image, degrees: -90) else { return nil }
        return Capture(image: image, scale: capture.scale)
    }

    static func flipHorizontal(_ capture: Capture) -> Capture? {
        guard let image = flip(capture.image, horizontal: true, vertical: false) else { return nil }
        return Capture(image: image, scale: capture.scale)
    }

    static func flipVertical(_ capture: Capture) -> Capture? {
        guard let image = flip(capture.image, horizontal: false, vertical: true) else { return nil }
        return Capture(image: image, scale: capture.scale)
    }

    /// Expand canvas by padding (Capture points) filled with `color`.
    static func expand(
        _ capture: Capture,
        top: CGFloat,
        left: CGFloat,
        bottom: CGFloat,
        right: CGFloat,
        fill: NSColor
    ) -> Capture? {
        let scale = capture.scale
        let newWidth = max(1, Int(((capture.pointSize.width + left + right) * scale).rounded()))
        let newHeight = max(1, Int(((capture.pointSize.height + top + bottom) * scale).rounded()))
        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.setFillColor(fill.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let dest = CGRect(
            x: left * scale,
            y: bottom * scale,
            width: CGFloat(capture.image.width),
            height: CGFloat(capture.image.height)
        )
        context.draw(capture.image, in: dest)
        guard let image = context.makeImage() else { return nil }
        return Capture(image: image, scale: scale)
    }

    /// Place `other` into `rect` (Capture points) on `base`.
    static func combine(base: Capture, other: Capture, into rect: CGRect) -> Capture? {
        let scale = base.scale
        guard let context = CGContext(
            data: nil,
            width: base.image.width,
            height: base.image.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: base.image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(base.image, in: CGRect(x: 0, y: 0, width: base.image.width, height: base.image.height))
        let dest = CGRect(
            x: rect.minX * scale,
            y: (base.pointSize.height - rect.maxY) * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )
        context.interpolationQuality = .high
        context.draw(other.image, in: dest)
        guard let image = context.makeImage() else { return nil }
        return Capture(image: image, scale: scale)
    }

    /// Makes pixels near the corner-sampled backdrop color transparent (window Capture matte).
    static func removeBackground(_ capture: Capture, tolerance: CGFloat) -> Capture? {
        let image = capture.image
        let width = image.width
        let height = image.height
        guard width > 2, height > 2 else { return nil }
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let ok = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard ok else { return nil }

        func color(at x: Int, y: Int) -> (r: Int, g: Int, b: Int) {
            let i = (y * width + x) * 4
            return (Int(pixels[i]), Int(pixels[i + 1]), Int(pixels[i + 2]))
        }
        let samples = [
            color(at: 0, y: 0),
            color(at: width - 1, y: 0),
            color(at: 0, y: height - 1),
            color(at: width - 1, y: height - 1),
        ]
        let avgR = samples.map(\.r).reduce(0, +) / samples.count
        let avgG = samples.map(\.g).reduce(0, +) / samples.count
        let avgB = samples.map(\.b).reduce(0, +) / samples.count
        let tol = Int(tolerance)

        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                let dr = abs(Int(pixels[i]) - avgR)
                let dg = abs(Int(pixels[i + 1]) - avgG)
                let db = abs(Int(pixels[i + 2]) - avgB)
                if dr <= tol && dg <= tol && db <= tol {
                    pixels[i + 3] = 0
                }
            }
        }

        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let result = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(
                    rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
                        | CGBitmapInfo.byteOrder32Big.rawValue
                ),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              )
        else { return nil }
        return Capture(image: result, scale: capture.scale)
    }

    // MARK: Annotation remapping

    static func offsetAnnotations(_ annotations: [Annotation], by delta: CGPoint) -> [Annotation] {
        annotations.map { annotation in
            var next = annotation
            next.kind = mapKind(annotation.kind) { CGPoint(x: $0.x + delta.x, y: $0.y + delta.y) }
            return next
        }
    }

    static func scaleAnnotations(_ annotations: [Annotation], from oldSize: CGSize, to newSize: CGSize) -> [Annotation] {
        let sx = newSize.width / max(oldSize.width, 0.001)
        let sy = newSize.height / max(oldSize.height, 0.001)
        return annotations.map { annotation in
            var next = annotation
            next.kind = mapKind(annotation.kind) { CGPoint(x: $0.x * sx, y: $0.y * sy) }
            if case let .number(center, radius, value) = next.kind {
                next.kind = .number(center: center, radius: radius * min(sx, sy), value: value)
            }
            return next
        }
    }

    static func cropAnnotations(_ annotations: [Annotation], by rect: CGRect) -> [Annotation] {
        offsetAnnotations(annotations, by: CGPoint(x: -rect.minX, y: -rect.minY))
    }

    static func rotateAnnotations90CW(_ annotations: [Annotation], canvasSize: CGSize) -> [Annotation] {
        annotations.map { annotation in
            var next = annotation
            next.kind = mapKind(annotation.kind) { point in
                CGPoint(x: canvasSize.height - point.y, y: point.x)
            }
            next.rotation += .pi / 2
            return next
        }
    }

    static func flipAnnotationsH(_ annotations: [Annotation], canvasWidth: CGFloat) -> [Annotation] {
        annotations.map { annotation in
            var next = annotation
            next.kind = mapKind(annotation.kind) { CGPoint(x: canvasWidth - $0.x, y: $0.y) }
            return next
        }
    }

    static func flipAnnotationsV(_ annotations: [Annotation], canvasHeight: CGFloat) -> [Annotation] {
        annotations.map { annotation in
            var next = annotation
            next.kind = mapKind(annotation.kind) { CGPoint(x: $0.x, y: canvasHeight - $0.y) }
            return next
        }
    }

    private static func mapKind(_ kind: AnnotationKind, _ transform: (CGPoint) -> CGPoint) -> AnnotationKind {
        switch kind {
        case let .arrow(start, end):
            return .arrow(start: transform(start), end: transform(end))
        case let .rectangle(rect):
            return .rectangle(rect: transformRect(rect, transform))
        case let .ellipse(rect):
            return .ellipse(rect: transformRect(rect, transform))
        case let .censor(rect):
            return .censor(rect: transformRect(rect, transform))
        case let .text(rect, string):
            return .text(rect: transformRect(rect, transform), string: string)
        case let .pencil(points):
            return .pencil(points: points.map(transform))
        case let .number(center, radius, value):
            return .number(center: transform(center), radius: radius, value: value)
        case let .stamp(rect, emoji):
            return .stamp(rect: transformRect(rect, transform), emoji: emoji)
        case let .highlight(points):
            return .highlight(points: points.map(transform))
        case let .measure(start, end, showsSize):
            return .measure(start: transform(start), end: transform(end), showsSize: showsSize)
        case let .spotlight(rect, shape):
            return .spotlight(rect: transformRect(rect, transform), shape: shape)
        }
    }

    private static func transformRect(_ rect: CGRect, _ transform: (CGPoint) -> CGPoint) -> CGRect {
        let a = transform(CGPoint(x: rect.minX, y: rect.minY))
        let b = transform(CGPoint(x: rect.maxX, y: rect.maxY))
        return CGRect(
            x: min(a.x, b.x),
            y: min(a.y, b.y),
            width: abs(b.x - a.x),
            height: abs(b.y - a.y)
        )
    }

    // MARK: Pixel helpers

    private static func redraw(_ image: CGImage, width: Int, height: Int) -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    private static func rotate(_ image: CGImage, degrees: CGFloat) -> CGImage? {
        let radians = degrees * .pi / 180
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let newWidth = abs(cos(radians) * width) + abs(sin(radians) * height)
        let newHeight = abs(sin(radians) * width) + abs(cos(radians) * height)
        guard let context = CGContext(
            data: nil,
            width: Int(newWidth.rounded()),
            height: Int(newHeight.rounded()),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.translateBy(x: newWidth / 2, y: newHeight / 2)
        context.rotate(by: radians)
        context.draw(image, in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
        return context.makeImage()
    }

    private static func flip(_ image: CGImage, horizontal: Bool, vertical: Bool) -> CGImage? {
        let width = image.width
        let height = image.height
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.translateBy(
            x: horizontal ? CGFloat(width) : 0,
            y: vertical ? CGFloat(height) : 0
        )
        context.scaleBy(x: horizontal ? -1 : 1, y: vertical ? -1 : 1)
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }
}
