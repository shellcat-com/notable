import AppKit
import CoreGraphics

// MARK: - Geometry helpers

extension CGRect {
    /// Builds a normalized rect from two arbitrary corner points (drag start/end).
    init(corner a: CGPoint, corner b: CGPoint) {
        self.init(
            x: min(a.x, b.x),
            y: min(a.y, b.y),
            width: abs(a.x - b.x),
            height: abs(a.y - b.y)
        )
    }

    var area: CGFloat { width * height }
}

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}

// MARK: - Displays

extension NSScreen {
    /// The Core Graphics display ID backing this screen (0 if unavailable).
    var displayID: CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (deviceDescription[key] as? NSNumber)?.uint32Value ?? 0
    }

    static func screen(forDisplayID id: CGDirectDisplayID) -> NSScreen? {
        screens.first { $0.displayID == id }
    }
}
