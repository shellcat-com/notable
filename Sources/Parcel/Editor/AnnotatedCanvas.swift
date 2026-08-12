import SwiftUI

/// Renders the Capture plus its Annotations. One code path serves both the interactive display
/// (with `scale` = fit zoom) and export (with `scale` = 1, rasterized full-res by `ImageRenderer`).
///
/// The base Capture is a static `Image` behind a transparent `Canvas`, so live drawing/moving only
/// re-renders the vector Annotations — not the (potentially 5K) base image every frame. Censors
/// sample the blurred/pixelated copies of the (adjusted) Capture, clipped to their rects. All
/// Spotlights composite as ONE grouped dim backdrop with their union punched out, drawn before the
/// vector marks so arrows/text stay bright above the dim.
struct AnnotatedCanvas: View {
    let base: NSImage
    let blurred: CGImage
    let pixelated: CGImage
    let pointSize: CGSize
    /// View points per Capture point (fit zoom on screen, 1 on export).
    let scale: CGFloat
    /// Intrinsic points→pixels factor of the Capture (NOT the view zoom) — Measure labels only.
    let captureScale: CGFloat
    var annotations: [Annotation]
    var draft: Annotation?

    static let spotlightDim = 0.55

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
                drawSpotlightDim(in: &context)
                for annotation in annotations where !annotation.kind.isSpotlight {
                    draw(annotation, in: &context)
                }
                if let draft, !draft.kind.isSpotlight { draw(draft, in: &context) }
            }
            .frame(width: viewSize.width, height: viewSize.height)
        }
        .frame(width: viewSize.width, height: viewSize.height)
    }

    // MARK: Drawing (Capture coordinates)

    private func draw(_ annotation: Annotation, in context: inout GraphicsContext) {
        let style = annotation.style
        let color = GraphicsContext.Shading.color(style.color.color)
        let center = annotation.kind.boundingBox.center
        let rotation = annotation.rotation

        context.drawLayer { layer in
            if rotation != 0 {
                layer.translateBy(x: center.x, y: center.y)
                layer.rotate(by: .radians(rotation))
                layer.translateBy(x: -center.x, y: -center.y)
            }
            drawKind(annotation.kind, style: style, color: color, in: &layer)
        }
    }

    private func drawKind(
        _ kind: AnnotationKind, style: AnnotationStyle, color: GraphicsContext.Shading,
        in context: inout GraphicsContext
    ) {
        switch kind {
        case let .arrow(start, end):
            drawArrow(from: start, to: end, style: style, in: &context)

        case let .rectangle(rect):
            context.stroke(
                Path(rect.standardized),
                with: color,
                style: StrokeStyle(lineWidth: style.lineWidth, lineJoin: .round)
            )

        case let .ellipse(rect):
            context.stroke(
                Path(ellipseIn: rect.standardized),
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
            drawCensor(rect: rect.standardized, style: style, in: &context)

        case let .text(rect, string):
            drawText(string, in: rect, style: style, in: &context)

        case let .number(center, radius, value):
            drawNumber(center: center, radius: radius, value: value, style: style, in: &context)

        case let .stamp(rect, emoji):
            drawStamp(emoji, in: rect.standardized, in: &context)

        case let .highlight(points):
            drawHighlight(points, style: style, in: &context)

        case let .measure(start, end, showsSize):
            drawMeasure(from: start, to: end, showsSize: showsSize, style: style, in: &context)

        case .spotlight:
            break // composited as a group by drawSpotlightDim(in:)
        }
    }

    // MARK: Arrow (5 styles)

    private func drawArrow(
        from start: CGPoint, to end: CGPoint, style: AnnotationStyle, in context: inout GraphicsContext
    ) {
        let color = GraphicsContext.Shading.color(style.color.color)
        let width = style.lineWidth
        let stroke = StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)

        switch style.arrowStyle {
        case .standard, .open, .double:
            var shaft = Path()
            shaft.move(to: start)
            shaft.addLine(to: end)
            context.stroke(shaft, with: color, style: stroke)

            let angle = atan2(end.y - start.y, end.x - start.x)
            drawArrowHead(at: end, angle: angle, width: width, filled: style.arrowStyle != .open, color: color, in: &context)
            if style.arrowStyle == .double {
                drawArrowHead(at: start, angle: angle + .pi, width: width, filled: true, color: color, in: &context)
            }

        case .curved:
            let control = ArrowGeometry.curveControl(start: start, end: end)
            var shaft = Path()
            shaft.move(to: start)
            shaft.addQuadCurve(to: end, control: control)
            context.stroke(shaft, with: color, style: stroke)
            // Head follows the end tangent (control → end).
            let angle = atan2(end.y - control.y, end.x - control.x)
            drawArrowHead(at: end, angle: angle, width: width, filled: true, color: color, in: &context)

        case .elbow:
            let corner = ArrowGeometry.elbowCorner(start: start, end: end)
            var shaft = Path()
            shaft.move(to: start)
            shaft.addLine(to: corner)
            shaft.addLine(to: end)
            context.stroke(shaft, with: color, style: stroke)
            let angle = atan2(end.y - corner.y, end.x - corner.x)
            drawArrowHead(at: end, angle: angle, width: width, filled: true, color: color, in: &context)
        }
    }

    private func drawArrowHead(
        at tip: CGPoint, angle: CGFloat, width: CGFloat, filled: Bool,
        color: GraphicsContext.Shading, in context: inout GraphicsContext
    ) {
        let headLength = max(12, width * 3.2)
        let spread = CGFloat.pi / 7
        let left = CGPoint(
            x: tip.x - headLength * cos(angle - spread),
            y: tip.y - headLength * sin(angle - spread)
        )
        let right = CGPoint(
            x: tip.x - headLength * cos(angle + spread),
            y: tip.y - headLength * sin(angle + spread)
        )

        if filled {
            var head = Path()
            head.move(to: tip)
            head.addLine(to: left)
            head.addLine(to: right)
            head.closeSubpath()
            context.fill(head, with: color)
        } else {
            var chevron = Path()
            chevron.move(to: left)
            chevron.addLine(to: tip)
            chevron.addLine(to: right)
            context.stroke(
                chevron, with: color,
                style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
            )
        }
    }

    // MARK: Censor (4 modes)

    private func drawCensor(rect: CGRect, style: AnnotationStyle, in context: inout GraphicsContext) {
        guard rect.width > 0, rect.height > 0 else { return }
        switch style.censorMode {
        case .blur:
            drawImageClipped(blurred, to: rect, in: &context)
        case .pixelate:
            drawImageClipped(pixelated, to: rect, in: &context)
        case .solid:
            context.fill(Path(rect), with: .color(style.color.color))
        case .erase:
            if let cg = base.cgImage(forProposedRect: nil, context: nil, hints: nil),
               let fill = CensorEraseSampler.averageSurroundingColor(in: rect, image: cg, pointSize: pointSize) {
                context.fill(Path(rect), with: .color(fill.color))
            } else {
                context.fill(Path(rect), with: .color(style.color.color))
            }
        }
    }

    private func drawImageClipped(_ image: CGImage, to rect: CGRect, in context: inout GraphicsContext) {
        context.drawLayer { layer in
            layer.clip(to: Path(rect))
            let img = Image(decorative: image, scale: 1, orientation: .up)
            layer.draw(img, in: CGRect(origin: .zero, size: pointSize))
        }
    }

    // MARK: Text

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

    // MARK: Numbered marker

    private func drawNumber(
        center: CGPoint, radius: CGFloat, value: Int, style: AnnotationStyle, in context: inout GraphicsContext
    ) {
        let box = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: box), with: .color(style.color.color))
        context.stroke(
            Path(ellipseIn: box), with: .color(.white),
            style: StrokeStyle(lineWidth: max(1, radius * 0.14))
        )
        let text = context.resolve(
            Text(verbatim: String(value))
                .font(.system(size: radius * 1.1, weight: .semibold))
                .foregroundColor(.white)
        )
        let size = text.measure(in: CGSize(width: radius * 3, height: radius * 3))
        context.draw(
            text,
            in: CGRect(
                x: center.x - size.width / 2, y: center.y - size.height / 2,
                width: size.width, height: size.height
            )
        )
    }

    // MARK: Stamp

    private func drawStamp(_ emoji: String, in rect: CGRect, in context: inout GraphicsContext) {
        guard !emoji.isEmpty, rect.width > 0, rect.height > 0 else { return }
        let text = context.resolve(Text(verbatim: emoji).font(.system(size: min(rect.width, rect.height))))
        let size = text.measure(
            in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        )
        context.draw(
            text,
            in: CGRect(
                x: rect.midX - size.width / 2, y: rect.midY - size.height / 2,
                width: size.width, height: size.height
            )
        )
    }

    // MARK: Highlighter

    /// One drawLayer carrying the opacity so a self-crossing stroke composites once and stays
    /// uniform (per-segment alpha would darken crossings).
    private func drawHighlight(_ points: [CGPoint], style: AnnotationStyle, in context: inout GraphicsContext) {
        guard let first = points.first else { return }
        let width = max(style.lineWidth * 4, 14)
        context.drawLayer { layer in
            layer.opacity = 0.35
            if points.count == 1 {
                layer.fill(
                    Path(ellipseIn: CGRect(x: first.x - width / 2, y: first.y - width / 2, width: width, height: width)),
                    with: .color(style.color.color)
                )
            } else {
                var path = Path()
                path.addLines(points)
                layer.stroke(
                    path, with: .color(style.color.color),
                    style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }

    // MARK: Measure

    private func drawMeasure(
        from start: CGPoint, to end: CGPoint, showsSize: Bool, style: AnnotationStyle,
        in context: inout GraphicsContext
    ) {
        let shade = GraphicsContext.Shading.color(style.color.color)

        var line = Path()
        line.move(to: start)
        line.addLine(to: end)
        context.stroke(line, with: shade, style: StrokeStyle(lineWidth: style.lineWidth))

        // Perpendicular end ticks.
        let angle = atan2(end.y - start.y, end.x - start.x)
        let perp = angle + .pi / 2
        let tick = max(6, style.lineWidth * 2)
        for point in [start, end] {
            var tickPath = Path()
            tickPath.move(to: CGPoint(x: point.x - tick * cos(perp), y: point.y - tick * sin(perp)))
            tickPath.addLine(to: CGPoint(x: point.x + tick * cos(perp), y: point.y + tick * sin(perp)))
            context.stroke(tickPath, with: shade, style: StrokeStyle(lineWidth: style.lineWidth, lineCap: .round))
        }

        // Label reports CAPTURE PIXELS (points × captureScale) — true output-file dimensions.
        let lengthPx = Int((start.distance(to: end) * captureScale).rounded())
        var label = "\(lengthPx) px"
        if showsSize {
            let wPx = Int((abs(end.x - start.x) * captureScale).rounded())
            let hPx = Int((abs(end.y - start.y) * captureScale).rounded())
            label += "  \(wPx)×\(hPx)"
        }

        let fontSize = max(11, style.lineWidth * 3)
        let text = context.resolve(
            Text(verbatim: label).font(.system(size: fontSize, weight: .medium)).foregroundColor(.white)
        )
        let textSize = text.measure(in: CGSize(width: 4000, height: 4000))
        let pad = fontSize * 0.4
        let mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let normal = CGPoint(x: -sin(angle), y: cos(angle))
        let offset = textSize.height / 2 + pad + style.lineWidth + 2
        let labelCenter = CGPoint(x: mid.x + normal.x * offset, y: mid.y + normal.y * offset)
        let background = CGRect(
            x: labelCenter.x - textSize.width / 2 - pad,
            y: labelCenter.y - textSize.height / 2 - pad,
            width: textSize.width + pad * 2,
            height: textSize.height + pad * 2
        )
        context.fill(Path(roundedRect: background, cornerRadius: pad + 2), with: shade)
        context.draw(
            text,
            in: CGRect(
                x: labelCenter.x - textSize.width / 2, y: labelCenter.y - textSize.height / 2,
                width: textSize.width, height: textSize.height
            )
        )
    }

    // MARK: Spotlight (grouped backdrop)

    /// One dim fill over the whole Capture with the UNION of all Spotlight shapes punched out via
    /// destinationOut — inside a drawLayer so the punch only subtracts from the dim, never from
    /// the base or other marks. Includes the live draft so drawing previews correctly.
    private func drawSpotlightDim(in context: inout GraphicsContext) {
        var holes: [Path] = []
        func addHole(_ rect: CGRect, _ shape: SpotlightShape) {
            let r = rect.standardized
            guard r.width > 0, r.height > 0 else { return }
            holes.append(shape == .ellipse ? Path(ellipseIn: r) : Path(r))
        }
        for annotation in annotations {
            if case let .spotlight(rect, shape) = annotation.kind { addHole(rect, shape) }
        }
        if let draft, case let .spotlight(rect, shape) = draft.kind { addHole(rect, shape) }
        guard !holes.isEmpty else { return }

        context.drawLayer { layer in
            layer.fill(
                Path(CGRect(origin: .zero, size: pointSize)),
                with: .color(.black.opacity(Self.spotlightDim))
            )
            layer.blendMode = .destinationOut
            for hole in holes { layer.fill(hole, with: .color(.black)) }
        }
    }
}
