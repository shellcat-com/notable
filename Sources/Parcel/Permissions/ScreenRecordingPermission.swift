import AppKit
import CoreGraphics
import ScreenCaptureKit

/// Thin wrapper over the Screen Recording TCC permission that ScreenCaptureKit requires.
///
/// macOS quirk: the very first `CGRequestScreenCaptureAccess()` adds the app to the Screen
/// Recording list and shows the system prompt, but the running process usually keeps reading
/// `false` until it is relaunched. On recent macOS releases it can also lag behind the actual
/// ScreenCaptureKit grant for an ad-hoc dev build, so Capture startup treats this as advisory.
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

    /// Requests access when the preflight probe says it is missing, but intentionally does not
    /// require the immediate result to be true. The capture attempt itself is the source of truth.
    static func requestIfNeeded() {
        if !isGranted { CGRequestScreenCaptureAccess() }
    }

    /// Uses the same framework as Capture/recording to verify the grant. This is intentionally
    /// separate from `isGranted` because TCC preflight can be stale for local dev builds.
    static func canUseCaptureAPI() async -> Bool {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false, onScreenWindowsOnly: true
            )
            return !content.displays.isEmpty
        } catch {
            return false
        }
    }

    /// Best-effort permission probe for UI and preflight checks. Preflight is fast but can lag
    /// behind the actual ScreenCaptureKit grant; the capture API probe is the fallback.
    static func hasEffectiveAccess() async -> Bool {
        if isGranted { return true }
        return await canUseCaptureAPI()
    }

    /// Deep-link to the Screen Recording pane in System Settings.
    static func openSystemSettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
