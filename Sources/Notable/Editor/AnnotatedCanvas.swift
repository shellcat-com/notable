import SwiftUI

/// Renders the Capture plus its Annotations. One code path serves both the interactive display
/// (with `scale` = zoom) and export (with `scale` = 1, rasterized full-res by `ImageRenderer`).
///
/// The base Capture is a static `Image` behind a transparent `Canvas`, so live drawing/moving only
/// re-renders the vector Annotations — not the (potentially 5K) base image every frame. The blurred
/// Capture is drawn, clipped, only inside Censor rects.
struct AnnotatedCanvas: View {
    let base: NSImage
    let blurred: CGImage
    let pointSize: CGSize
    /// View points per Capture point.
    let scale: CGFloat
    var annotations: [Annotation]
    var draft: Annotation?

    private var viewSize: CGSize {
        CGSize(width: pointSize.width * scale, height: pointSize.height * scale)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(nsImage: base)
                .resizable()
                .interpolation(.high)
                .frame(width: viewSize.width, height: viewSize.height)

            Canvas { context, _ in
                context.scaleBy(x: scale, y: scale) // draw in Capture coordinates
                for annotation in annotations { draw(annotation, in: &context) }
                if let draft { draw(draft, in: &context) }
            }
            .frame(width: viewSize.width, height: viewSize.height)
        }
        .frame(width: viewSize.width, height: viewSize.height)
    }

    // MARK: Drawing (Capture coordinates)

    private func draw(_ annotation: Annotation, in context: inout GraphicsContext) {
        let style = annotation.style
        let color = GraphicsContext.Shading.color(style.color.color)

        switch annotation.kind {
        case let .arrow(start, end):
            drawArrow(from: start, to: end, width: style.lineWidth, color: color, in: &context)

        case let .rectangle(rect):
            context.stroke(
                Path(rect.standardized),
                with: color,
                style: StrokeStyle(lineWidth: style.lineWidth, lineJoin: .round)
            )

        case let .pencil(points):
            var path = Path()
            path.addLines(points)
            context.stroke(
                path,
                with: color,
                style: StrokeStyle(lineWidth: style.lineWidth, lineCap: .round, lineJoin: .round)
            )

        case let .censor(rect):
            drawCensor(rect: rect.standardized, in: &context)

        case let .text(rect, string):
            drawText(string, in: rect, style: style, in: &context)
        }
    }

    private func drawArrow(
        from start: CGPoint, to end: CGPoint, width: CGFloat,
        color: GraphicsContext.Shading, in context: inout GraphicsContext
    ) {
        var shaft = Path()
        shaft.move(to: start)
        shaft.addLine(to: end)
        context.stroke(shaft, with: color, style: StrokeStyle(lineWidth: width, lineCap: .round))

        let angle = atan2(end.y - start.y, end.x - start.x)
        let headLength = max(12, width * 3.2)
        let spread = CGFloat.pi / 7
        let left = CGPoint(
            x: end.x - headLength * cos(angle - spread),
            y: end.y - headLength * sin(angle - spread)
        )
        let right = CGPoint(
            x: end.x - headLength * cos(angle + spread),
            y: end.y - headLength * sin(angle + spread)
        )
        var head = Path()
        head.move(to: end)
        head.addLine(to: left)
        head.addLine(to: right)
        head.closeSubpath()
        context.fill(head, with: color)
    }

    private func drawCensor(rect: CGRect, in context: inout GraphicsContext) {
        guard rect.width > 0, rect.height > 0 else { return }
        context.drawLayer { layer in
            layer.clip(to: Path(rect))
            let image = Image(decorative: blurred, scale: 1, orientation: .up)
            layer.draw(image, in: CGRect(origin: .zero, size: pointSize))
        }
    }

    private func drawText(
        _ string: String, in rect: CGRect, style: AnnotationStyle, in context: inout GraphicsContext
    ) {
        guard !string.isEmpty else { return }
        let text = Text(string)
            .font(.system(size: style.fontSize))
            .foregroundColor(style.color.color)
        let resolved = context.resolve(text)
        context.draw(resolved, in: rect.standardized)
    }
}
