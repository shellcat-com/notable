import SwiftUI

/// Display-only bubbles for the utility Tools. Rendered as `allowsHitTesting(false)` siblings in
/// EditorCanvasView's ZStack — structurally outside AnnotatedCanvas/BeautifyCanvas, so they can
/// never appear in any Copy/Save output.

/// Magnifies a window of true Capture pixels (nearest-neighbor) with a pixel grid, center
/// highlight, and a hex + coordinate readout.
struct LoupeView: View {
    static let sourceCells = 15 // odd → a true center pixel
    static let zoom: CGFloat = 8
    static var diameter: CGFloat { CGFloat(sourceCells) * zoom }

    let image: CGImage
    let centerPixel: (x: Int, y: Int)
    let color: RGBAColor?

    var body: some View {
        VStack(spacing: 5) {
            magnifier
            readout
        }
    }

    private var magnifier: some View {
        Canvas { context, size in
            let cells = Self.sourceCells
            let zoom = Self.zoom
            let half = cells / 2

            // Source pixel window, clamped to the image; draw offset keeps the cursor pixel
            // centered even at edges.
            let source = CGRect(x: CGFloat(centerPixel.x - half), y: CGFloat(centerPixel.y - half),
                                width: CGFloat(cells), height: CGFloat(cells))
            let bounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
            let clamped = source.intersection(bounds)
            if !clamped.isNull, let crop = image.cropping(to: clamped) {
                let dest = CGRect(
                    x: (clamped.minX - source.minX) * zoom,
                    y: (clamped.minY - source.minY) * zoom,
                    width: clamped.width * zoom,
                    height: clamped.height * zoom
                )
                context.draw(
                    Image(decorative: crop, scale: 1, orientation: .up).interpolation(.none),
                    in: dest
                )
            }

            // Pixel grid.
            var grid = Path()
            for i in 0...cells {
                let offset = CGFloat(i) * zoom
                grid.move(to: CGPoint(x: offset, y: 0))
                grid.addLine(to: CGPoint(x: offset, y: size.height))
                grid.move(to: CGPoint(x: 0, y: offset))
                grid.addLine(to: CGPoint(x: size.width, y: offset))
            }
            context.stroke(grid, with: .color(.white.opacity(0.15)), lineWidth: 0.5)

            // Center cell highlight.
            let center = CGRect(x: CGFloat(half) * zoom, y: CGFloat(half) * zoom, width: zoom, height: zoom)
            context.stroke(Path(center.insetBy(dx: -0.75, dy: -0.75)), with: .color(.black.opacity(0.6)), lineWidth: 1.5)
            context.stroke(Path(center), with: .color(.white), lineWidth: 1)
        }
        .frame(width: Self.diameter, height: Self.diameter)
        .background(Color.black)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Color.white.opacity(0.9), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
    }

    private var readout: some View {
        HStack(spacing: 6) {
            if let color {
                RoundedRectangle(cornerRadius: 3)
                    .fill(color.color)
                    .frame(width: 12, height: 12)
                    .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(.white.opacity(0.4), lineWidth: 0.5))
                Text(color.hexString)
            }
            Text("\(centerPixel.x), \(centerPixel.y)").foregroundStyle(.secondary)
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(.black.opacity(0.78), in: Capsule())
    }
}

/// Small magnified patch + color chip + hex for the pixel under the cursor.
struct EyedropperView: View {
    static let patchCells = 9
    static let zoom: CGFloat = 10
    static var patchSize: CGFloat { CGFloat(patchCells) * zoom }

    let image: CGImage
    let centerPixel: (x: Int, y: Int)
    let color: RGBAColor?

    var body: some View {
        VStack(spacing: 5) {
            patch
            chip
        }
    }

    private var patch: some View {
        Canvas { context, _ in
            let cells = Self.patchCells
            let zoom = Self.zoom
            let half = cells / 2
            let source = CGRect(x: CGFloat(centerPixel.x - half), y: CGFloat(centerPixel.y - half),
                                width: CGFloat(cells), height: CGFloat(cells))
            let bounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
            let clamped = source.intersection(bounds)
            if !clamped.isNull, let crop = image.cropping(to: clamped) {
                let dest = CGRect(
                    x: (clamped.minX - source.minX) * zoom,
                    y: (clamped.minY - source.minY) * zoom,
                    width: clamped.width * zoom,
                    height: clamped.height * zoom
                )
                context.draw(
                    Image(decorative: crop, scale: 1, orientation: .up).interpolation(.none),
                    in: dest
                )
            }
            let center = CGRect(x: CGFloat(half) * zoom, y: CGFloat(half) * zoom, width: zoom, height: zoom)
            context.stroke(Path(center.insetBy(dx: -0.75, dy: -0.75)), with: .color(.black.opacity(0.6)), lineWidth: 1.5)
            context.stroke(Path(center), with: .color(.white), lineWidth: 1)
        }
        .frame(width: Self.patchSize, height: Self.patchSize)
        .background(Color.black)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Color.white.opacity(0.9), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.35), radius: 5, y: 2)
    }

    private var chip: some View {
        HStack(spacing: 6) {
            if let color {
                RoundedRectangle(cornerRadius: 3)
                    .fill(color.color)
                    .frame(width: 14, height: 14)
                    .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(.white.opacity(0.4), lineWidth: 0.5))
                Text(color.hexString)
            } else {
                Text("—")
            }
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.black.opacity(0.78), in: Capsule())
    }
}
