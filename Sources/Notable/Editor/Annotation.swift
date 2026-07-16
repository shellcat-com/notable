import SwiftUI

// MARK: - Tool

/// The active annotation mode. `.select` edits existing Annotations; the rest create new ones.
enum Tool: String, CaseIterable, Identifiable {
    case select, arrow, rectangle, text, pencil, censor

    var id: String { rawValue }
    var isDrawing: Bool { self != .select }

    var symbol: String {
        switch self {
        case .select: return "cursorarrow"
        case .arrow: return "arrow.up.right"
        case .rectangle: return "rectangle"
        case .text: return "textformat"
        case .pencil: return "scribble.variable"
        case .censor: return "eye.slash"
        }
    }

    var label: String {
        switch self {
        case .select: return "Select"
        case .arrow: return "Arrow"
        case .rectangle: return "Rectangle"
        case .text: return "Text"
        case .pencil: return "Pencil"
        case .censor: return "Blur"
        }
    }
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

    static let red = RGBAColor(red: 0.98, green: 0.24, blue: 0.19)
    static let yellow = RGBAColor(red: 1.0, green: 0.80, blue: 0.0)
    static let blue = RGBAColor(red: 0.0, green: 0.48, blue: 1.0)
    static let black = RGBAColor(red: 0.0, green: 0.0, blue: 0.0)
    static let white = RGBAColor(red: 1.0, green: 1.0, blue: 1.0)
}

struct AnnotationStyle: Equatable {
    var color: RGBAColor
    var lineWidth: CGFloat
    var fontSize: CGFloat
}

// MARK: - Annotation

/// A resize/move handle on a selected Annotation.
enum Handle: Equatable {
    case topLeft, topRight, bottomLeft, bottomRight // rect-like
    case start, end                                 // arrow endpoints
}

/// The geometry + payload of one Annotation, in **Capture point coordinates** (resolution
/// independent). Rendering and hit-testing convert to view/pixel space via a scale factor.
enum AnnotationKind: Equatable {
    case arrow(start: CGPoint, end: CGPoint)
    case rectangle(rect: CGRect)
    case censor(rect: CGRect)
    case text(rect: CGRect, string: String)
    case pencil(points: [CGPoint])
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
}

// MARK: - Geometry

extension AnnotationKind {

    var boundingBox: CGRect {
        switch self {
        case let .arrow(start, end):
            return CGRect(corner: start, corner: end)
        case let .rectangle(rect), let .censor(rect), let .text(rect, _):
            return rect.standardized
        case let .pencil(points):
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
    func hitTest(_ point: CGPoint, tolerance: CGFloat, lineWidth: CGFloat) -> Bool {
        let slop = tolerance + lineWidth / 2
        switch self {
        case let .arrow(start, end):
            return point.distanceToSegment(start, end) <= slop
        case let .pencil(points):
            guard points.count > 1 else {
                return points.first.map { point.distance(to: $0) <= slop } ?? false
            }
            for i in 0..<(points.count - 1) where point.distanceToSegment(points[i], points[i + 1]) <= slop {
                return true
            }
            return false
        case .rectangle, .censor, .text:
            return boundingBox.insetBy(dx: -slop, dy: -slop).contains(point)
        }
    }

    /// Handles offered for direct resize. Pencil offers none (move + delete only in Phase 1).
    var handles: [(Handle, CGPoint)] {
        switch self {
        case let .arrow(start, end):
            return [(.start, start), (.end, end)]
        case let .rectangle(rect), let .censor(rect), let .text(rect, _):
            let r = rect.standardized
            return [
                (.topLeft, CGPoint(x: r.minX, y: r.minY)),
                (.topRight, CGPoint(x: r.maxX, y: r.minY)),
                (.bottomLeft, CGPoint(x: r.minX, y: r.maxY)),
                (.bottomRight, CGPoint(x: r.maxX, y: r.maxY)),
            ]
        case .pencil:
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
        case let .rectangle(rect):
            return .rectangle(rect: Self.resize(rect, handle: handle, to: point))
        case let .censor(rect):
            return .censor(rect: Self.resize(rect, handle: handle, to: point))
        case let .text(rect, string):
            return .text(rect: Self.resize(rect, handle: handle, to: point), string: string)
        case .pencil:
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
