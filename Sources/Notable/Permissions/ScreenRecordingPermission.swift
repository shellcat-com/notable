import AppKit
import CoreGraphics

/// Thin wrapper over the Screen Recording TCC permission that ScreenCaptureKit requires.
///
/// macOS quirk: the very first `CGRequestScreenCaptureAccess()` adds the app to the Screen
/// Recording list and shows the system prompt, but the running process usually keeps reading
/// `false` until it is relaunched. We surface that explicitly instead of failing silently.
enum ScreenRecordingPermission {

    static var isGranted: Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Trigger the system prompt / add the app to the list. Returns the (often still-false on
    /// first run) status immediately afterward.
    @discardableResult
    static func request() -> Bool {
        CGRequestScreenCaptureAccess()
        return CGPreflightScreenCaptureAccess()
    }

    /// Deep-link to the Screen Recording pane in System Settings.
    static func openSystemSettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
