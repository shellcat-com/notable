import AppKit
import CoreGraphics

/// A window detected on a frozen display, expressed in that display's local
/// top-left point coordinates (matching the SwiftUI Overlay coordinate space).
struct SnapWindow: Identifiable, Equatable {
    let id: Int
    let title: String
    let appName: String
    /// Top-left origin, points, local to the owning display.
    let frameInScreen: CGRect
}

enum SnapWindowPicker {
    /// The frontmost detected window under a local point is represented by the
    /// smallest containing frame, because ScreenCaptureKit gives us windows in display space.
    static func frontmostWindow(at point: CGPoint, windows: [SnapWindow]) -> SnapWindow? {
        windows
            .filter { $0.frameInScreen.contains(point) }
            .min { $0.frameInScreen.area < $1.frameInScreen.area }
    }
}

/// A single display, captured full-resolution at hotkey time and frozen for selection.
struct FrozenScreen: Identifiable {
    let id: CGDirectDisplayID
    let screen: NSScreen
    /// Full-resolution pixels of the display, top-left origin.
    let image: CGImage
    /// points → pixels factor for this display (backingScaleFactor).
    let scale: CGFloat
    /// Display size in points (the Overlay's coordinate space).
    let pointSize: CGSize
    /// Windows visible on this display, in local top-left points.
    let windows: [SnapWindow]

    /// The frontmost (smallest containing) window under a local point, if any.
    func window(at point: CGPoint) -> SnapWindow? {
        SnapWindowPicker.frontmostWindow(at: point, windows: windows)
    }
}

/// The user's confirmed Selection: which frozen display, and the rect within it.
struct SelectionResult {
    let screen: FrozenScreen
    /// Top-left origin, points, local to the display.
    let rectInPoints: CGRect
}

/// The finished Capture handed to the Editor: cropped full-resolution pixels.
struct Capture {
    let image: CGImage
    /// points → pixels factor, so the Editor can present at true point size.
    let scale: CGFloat

    /// The Capture's size in points (logical size for display/layout).
    var pointSize: CGSize {
        CGSize(width: CGFloat(image.width) / scale, height: CGFloat(image.height) / scale)
    }

    var pixelSize: CGSize {
        CGSize(width: image.width, height: image.height)
    }
}
