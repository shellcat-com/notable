import AppKit
import CoreGraphics
import ScreenCaptureKit

/// Thin wrapper over the Screen Recording TCC permission that ScreenCaptureKit requires.
///
/// Important: `CGRequestScreenCaptureAccess()` shows a system dialog that is useless when Parcel
/// is already listed in System Settings with the toggle ON but the **running binary's code
/// signature** no longer matches that grant (ad-hoc rebuilds, sandbox on/off, multiple .app
/// copies). Capture must **not** call that API on every attempt — try ScreenCaptureKit first,
/// then guide the user to remove/re-add the app in Settings.
enum ScreenRecordingPermission {

    static var isGranted: Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Explicit user action only (Preferences “Grant…”). Do not call from the Capture path.
    @discardableResult
    static func request() -> Bool {
        CGRequestScreenCaptureAccess()
        return CGPreflightScreenCaptureAccess()
    }

    /// Lists shareable displays via ScreenCaptureKit.
    static func canUseCaptureAPI() async -> Bool {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false, onScreenWindowsOnly: true
            )
            return !content.displays.isEmpty
        } catch {
            NSLog("Parcel: SCShareableContent probe failed — \(error)")
            return false
        }
    }

    /// Real capture probe — source of truth for whether this binary can Capture.
    static func canCaptureDisplay() async -> Bool {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false, onScreenWindowsOnly: true
            )
            guard let display = content.displays.first else {
                NSLog("Parcel: capture probe — no displays in shareable content")
                return false
            }
            if #available(macOS 14.0, *) {
                let filter = SCContentFilter(display: display, excludingWindows: [])
                let config = SCStreamConfiguration()
                config.width = 2
                config.height = 2
                config.showsCursor = false
                config.scalesToFit = false
                _ = try await SCScreenshotManager.captureImage(
                    contentFilter: filter, configuration: config
                )
            }
            return true
        } catch {
            NSLog("Parcel: capture probe failed — \(error)")
            return false
        }
    }

    /// True only when this process can actually capture pixels.
    /// Prefer `isGranted` for UI polling — calling ScreenCaptureKit while denied shows the
    /// system permission sheet on recent macOS.
    static func hasEffectiveAccess() async -> Bool {
        if isGranted { return await canCaptureDisplay() }
        return false
    }

    /// Preflight false while Settings may still show Parcel ON → signature mismatch.
    static var likelyNeedsRebuildRegrant: Bool {
        !isGranted
    }

    static func openSystemSettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    static func revealAppInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }
}
