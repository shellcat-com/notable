import SwiftUI

// MARK: - Tool

/// The active annotation mode. `.select` edits existing Annotations; drawing Tools create new
/// ones; utility Tools (Loupe, Eyedropper) are ephemeral overlays that never create Annotations.
enum Tool: String, CaseIterable, Identifiable {
    case select, arrow, rectangle, text, pencil, censor
    case number, stamp, highlighter, measure, spotlight
    case loupe, eyedropper

    var id: String { rawValue }

    /// Ephemeral inspection Tools: no Annotation, no undo, display-only overlay.
    var isUtility: Bool { self == .loupe || self == .eyedropper }
    var isDrawing: Bool { !isUtility && self != .select }

    var symbol: String {
        switch self {
        case .select: return "cursorarrow"
        case .arrow: return "arrow.up.right"
        case .rectangle: return "rectangle"
        case .text: return "textformat"
        case .pencil: return "scribble.variable"
        case .censor: return "eye.slash"
        case .number: return "1.circle"
        case .stamp: return "face.smiling"
        case .highlighter: return "highlighter"
        case .measure: return "ruler"
        case .spotlight: return "flashlight.on.fill"
        case .loupe: return "plus.magnifyingglass"
        case .eyedropper: return "eyedropper"
        }
    }

    var label: String {
        switch self {
        case .select: return "Select"
        case .arrow: return "Arrow"
        case .rectangle: return "Rectangle"
        case .text: return "Text"
        case .pencil: return "Pencil"
        case .censor: return "Censor"
        case .number: return "Number"
        case .stamp: return "Stamp"
        case .highlighter: return "Highlighter"
        case .measure: return "Measure"
        case .spotlight: return "Spotlight"
        case .loupe: return "Loupe"
        case .eyedropper: return "Eyedropper"
        }
    }
}

// MARK: - Appearance enums

/// Arrow appearance. Style affects head/shaft shape only; geometry stays (start, end).
enum ArrowStyle: String, CaseIterable, Identifiable, Equatable {
    case standard   // straight shaft + filled triangle head
    case open       // straight shaft + stroked chevron head
    case double     // straight shaft + filled heads at both ends
    case curved     // quadratic-bowed shaft + filled head along the end tangent
    case elbow      // right-angle shaft + filled head

    var id: String { rawValue }

    var label: String {
        switch self {
        case .standard: return "Arrow"
        case .open: return "Open Head"
        case .double: return "Double"
        case .curved: return "Curved"
        case .elbow: return "Elbow"
        }
    }

    var symbol: String {
        switch self {
        case .standard: return "arrow.up.right"
        case .open: return "chevron.up"
        case .double: return "arrow.left.and.right"
        case .curved: return "arrow.turn.right.up"
        case .elbow: return "arrow.turn.up.right"
        }
    }
}

/// How a Censor hides its region.
enum CensorMode: String, CaseIterable, Identifiable, Equatable {
    case blur       // gaussian blur of the (adjusted) Capture
    case pixelate   // mosaic of the (adjusted) Capture
    case solid      // opaque fill in the Annotation's color

    var id: String { rawValue }

    var label: String {
        switch self {
        case .blur: return "Blur"
        case .pixelate: return "Pixelate"
        case .solid: return "Solid"
        }
    }

    var symbol: String {
        switch self {
        case .blur: return "drop.fill"
        case .pixelate: return "square.grid.3x3.fill"
        case .solid: return "square.fill"
        }
    }
}

enum SpotlightShape: String, CaseIterable, Identifiable, Equatable, Hashable {
    case rectangle, ellipse

    var id: String { rawValue }
    var label: String { self == .rectangle ? "Rectangle" : "Ellipse" }
    var symbol: String { self == .rectangle ? "rectangle" : "oval" }
}

// MARK: - Style

/// A stored, resolution-independent color (sRGB) so Annotations are Codable-ready for later sync.
struct RGBAColor: Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red; self.green = green; self.blue = blue; self.alpha = alpha
    }

    init(_ color: Color) {
        let ns = NSColor(color).usingColorSpace(.sRGB) ?? .red
        red = Double(ns.redComponent)
        green = Double(ns.greenComponent)
        blue = Double(ns.blueComponent)
        alpha = Double(ns.alphaComponent)
    }

    var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha) }

    var hexString: String {
        String(
            format: "#%02X%02X%02X",
            Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded())
        )
    }

    static let red = RGBAColor(red: 0.98, green: 0.24, blue: 0.19)
    static let yellow = RGBAColor(red: 1.0, green: 0.80, blue: 0.0)
    static let blue = RGBAColor(red: 0.0, green: 0.48, blue: 1.0)
    static let black = RGBAColor(red: 0.0, green: 0.0, blue: 0.0)
    static let white = RGBAColor(red: 1.0, green: 1.0, blue: 1.0)
}

/// Appearance of one Annotation. Defaults keep the short memberwise init source-compatible;
/// arrowStyle is consulted only for `.arrow`, censorMode only for `.censor`.
struct AnnotationStyle: Equatable {
    var color: RGBAColor
    var lineWidth: CGFloat
    var fontSize: CGFloat
    var arrowStyle: ArrowStyle = .standard
    var censorMode: CensorMode = .blur
}

// MARK: - Annotation

/// A resize/move handle on a selected Annotation.
enum Handle: Equatable {
    case topLeft, topRight, bottomLeft, bottomRight // rect-like
    case start, end                                 // arrow/measure endpoints
}

/// The geometry + payload of one Annotation, in **Capture point coordinates** (resolution
/// independent). Rendering and hit-testing convert to view/pixel space via a scale factor.
enum AnnotationKind: Equatable {
    case arrow(start: CGPoint, end: CGPoint)
    case rectangle(rect: CGRect)
    case censor(rect: CGRect)
    case text(rect: CGRect, string: String)
    case pencil(points: [CGPoint])
    case number(center: CGPoint, radius: CGFloat, value: Int)
    case stamp(rect: CGRect, emoji: String)
    case highlight(points: [CGPoint])
    case measure(start: CGPoint, end: CGPoint, showsSize: Bool)
    case spotlight(rect: CGRect, shape: SpotlightShape)

    var isSpotlight: Bool {
        if case .spotlight = self { return true }
        return false
    }
}

/// One editable mark-up object composited over the Capture.
struct Annotation: Identifiable, Equatable {
    let id: UUID
    var kind: AnnotationKind
    var style: AnnotationStyle

    init(id: UUID = UUID(), kind: AnnotationKind, style: AnnotationStyle) {
        self.id = id
        self.kind = kind
        self.style = style
    }

    /// Style-aware hit test (arrow shafts follow their ArrowStyle; highlighter uses its true width).
    func hitTest(_ point: CGPoint, tolerance: CGFloat) -> Bool {
        kind.hitTest(point, tolerance: tolerance, lineWidth: style.lineWidth, arrowStyle: style.arrowStyle)
    }
}

// MARK: - Shared arrow geometry (drawing and hit-testing must agree)

enum ArrowGeometry {
    /// Control point for the `.curved` style: midpoint bowed perpendicular to the segment.
    static func curveControl(start: CGPoint, end: CGPoint) -> CGPoint {
        let mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let dx = end.x - start.x, dy = end.y - start.y
        let length = max(hypot(dx, dy), 0.001)
        // Unit perpendicular (rotate direction by -90°), bow by 18% of length.
        let bow = length * 0.18
        return CGPoint(x: mid.x - dy / length * bow, y: mid.y + dx / length * bow)
    }

    /// Corner for the `.elbow` style: horizontal leg first, then vertical to the tip.
    static func elbowCorner(start: CGPoint, end: CGPoint) -> CGPoint {
        CGPoint(x: end.x, y: start.y)
    }

    /// Points approximating the quad curve, for hit-testing the `.curved` shaft.
    static func curveSamples(start: CGPoint, end: CGPoint, count: Int = 16) -> [CGPoint] {
        let control = curveControl(start: start, end: end)
        var points: [CGPoint] = []
        points.reserveCapacity(count + 1)
        for i in 0...count {
            let t = CGFloat(i) / CGFloat(count)
            let mt: CGFloat = 1 - t
            let a: CGFloat = mt * mt
            let b: CGFloat = 2 * mt * t
            let c: CGFloat = t * t
            let x: CGFloat = a * start.x + b * control.x + c * end.x
            let y: CGFloat = a * start.y + b * control.y + c * end.y
            points.append(CGPoint(x: x, y: y))
        }
        return points
    }
}

// MARK: - Geometry

extension AnnotationKind {

    var boundingBox: CGRect {
        switch self {
        case let .arrow(start, end), let .measure(start, end, _):
            return CGRect(corner: start, corner: end)
        case let .rectangle(rect), let .censor(rect), let .text(rect, _),
             let .stamp(rect, _), let .spotlight(rect, _):
            return rect.standardized
        case let .number(center, radius, _):
            return CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        case let .pencil(points), let .highlight(points):
            guard let first = points.first else { return .zero }
            var minX = first.x, minY = first.y, maxX = first.x, maxY = first.y
            for p in points {
                minX = min(minX, p.x); minY = min(minY, p.y)
                maxX = max(maxX, p.x); maxY = max(maxY, p.y)
            }
            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
    }

    /// True if `point` (Capture coords) is close enough to select this Annotation.
    /// Prefer `Annotation.hitTest`, which forwards the owning style.
    func hitTest(
        _ point: CGPoint, tolerance: CGFloat, lineWidth: CGFloat, arrowStyle: ArrowStyle = .standard
    ) -> Bool {
        let slop = tolerance + lineWidth / 2
        switch self {
        case let .arrow(start, end):
            switch arrowStyle {
            case .standard, .open, .double:
                return point.distanceToSegment(start, end) <= slop
            case .elbow:
                let corner = ArrowGeometry.elbowCorner(start: start, end: end)
                return point.distanceToSegment(start, corner) <= slop
                    || point.distanceToSegment(corner, end) <= slop
            case .curved:
                return Self.hitsPolyline(ArrowGeometry.curveSamples(start: start, end: end), point: point, slop: slop)
            }

        case let .measure(start, end, _):
            return point.distanceToSegment(start, end) <= slop

        case let .pencil(points):
            return Self.hitsPolyline(points, point: point, slop: slop)

        case let .highlight(points):
            // Highlighter strokes are ~4× the nominal width; hit-test the real footprint.
            let effectiveWidth = max(lineWidth * 4, 14)
            return Self.hitsPolyline(points, point: point, slop: tolerance + effectiveWidth / 2)

        case let .number(center, radius, _):
            return point.distance(to: center) <= radius + slop

        case .rectangle, .censor, .text, .stamp, .spotlight:
            return boundingBox.insetBy(dx: -slop, dy: -slop).contains(point)
        }
    }

    private static func hitsPolyline(_ points: [CGPoint], point: CGPoint, slop: CGFloat) -> Bool {
        guard points.count > 1 else {
            return points.first.map { point.distance(to: $0) <= slop } ?? false
        }
        for i in 0..<(points.count - 1) where point.distanceToSegment(points[i], points[i + 1]) <= slop {
            return true
        }
        return false
    }

    /// Handles offered for direct resize. Pencil/highlight offer none (move + delete only).
    var handles: [(Handle, CGPoint)] {
        switch self {
        case let .arrow(start, end), let .measure(start, end, _):
            return [(.start, start), (.end, end)]
        case .rectangle, .censor, .text, .stamp, .spotlight, .number:
            let r = boundingBox
            return [
                (.topLeft, CGPoint(x: r.minX, y: r.minY)),
                (.topRight, CGPoint(x: r.maxX, y: r.minY)),
                (.bottomLeft, CGPoint(x: r.minX, y: r.maxY)),
                (.bottomRight, CGPoint(x: r.maxX, y: r.maxY)),
            ]
        case .pencil, .highlight:
            return []
        }
    }

    func translated(dx: CGFloat, dy: CGFloat) -> AnnotationKind {
        switch self {
        case let .arrow(start, end):
            return .arrow(start: start.offset(dx: dx, dy: dy), end: end.offset(dx: dx, dy: dy))
        case let .rectangle(rect):
            return .rectangle(rect: rect.offsetBy(dx: dx, dy: dy))
        case let .censor(rect):
            return .censor(rect: rect.offsetBy(dx: dx, dy: dy))
        case let .text(rect, string):
            return .text(rect: rect.offsetBy(dx: dx, dy: dy), string: string)
        case let .pencil(points):
            return .pencil(points: points.map { $0.offset(dx: dx, dy: dy) })
        case let .number(center, radius, value):
            return .number(center: center.offset(dx: dx, dy: dy), radius: radius, value: value)
        case let .stamp(rect, emoji):
            return .stamp(rect: rect.offsetBy(dx: dx, dy: dy), emoji: emoji)
        case let .highlight(points):
            return .highlight(points: points.map { $0.offset(dx: dx, dy: dy) })
        case let .measure(start, end, showsSize):
            return .measure(start: start.offset(dx: dx, dy: dy), end: end.offset(dx: dx, dy: dy), showsSize: showsSize)
        case let .spotlight(rect, shape):
            return .spotlight(rect: rect.offsetBy(dx: dx, dy: dy), shape: shape)
        }
    }

    func resized(handle: Handle, to point: CGPoint) -> AnnotationKind {
        switch self {
        case let .arrow(start, end):
            switch handle {
            case .start: return .arrow(start: point, end: end)
            case .end: return .arrow(start: start, end: point)
            default: return self
            }
        case let .measure(start, end, showsSize):
            switch handle {
            case .start: return .measure(start: point, end: end, showsSize: showsSize)
            case .end: return .measure(start: start, end: point, showsSize: showsSize)
            default: return self
            }
        case let .rectangle(rect):
            return .rectangle(rect: Self.resize(rect, handle: handle, to: point))
        case let .censor(rect):
            return .censor(rect: Self.resize(rect, handle: handle, to: point))
        case let .text(rect, string):
            return .text(rect: Self.resize(rect, handle: handle, to: point), string: string)
        case let .stamp(rect, emoji):
            return .stamp(rect: Self.resize(rect, handle: handle, to: point), emoji: emoji)
        case let .spotlight(rect, shape):
            return .spotlight(rect: Self.resize(rect, handle: handle, to: point), shape: shape)
        case let .number(center, _, value):
            // Centered resize: any corner drag sets the radius, center stays fixed.
            let radius = max(abs(point.x - center.x), abs(point.y - center.y))
            return .number(center: center, radius: max(radius, 8), value: value)
        case .pencil, .highlight:
            return self
        }
    }

    private static func resize(_ rect: CGRect, handle: Handle, to p: CGPoint) -> CGRect {
        let r = rect.standardized
        var minX = r.minX, minY = r.minY, maxX = r.maxX, maxY = r.maxY
        switch handle {
        case .topLeft: minX = p.x; minY = p.y
        case .topRight: maxX = p.x; minY = p.y
        case .bottomLeft: minX = p.x; maxY = p.y
        case .bottomRight: maxX = p.x; maxY = p.y
        default: break
        }
        return CGRect(corner: CGPoint(x: minX, y: minY), corner: CGPoint(x: maxX, y: maxY))
    }
}
