import CoreGraphics
import Foundation

/// User-tunable Capture / Overlay / after-Capture behavior.
enum CapturePreferences {
    private static let prefix = AppIdentity.defaultsPrefix

    /// After Capture, show the floating Quick Access panel instead of opening the Editor immediately.
    static var useQuickAccess: Bool {
        get { UserDefaults.standard.object(forKey: "\(prefix).capture.useQuickAccess") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.useQuickAccess") }
    }

    /// Seconds before Quick Access auto-closes (0 = stay until dismissed).
    static var quickAccessAutoCloseSeconds: Double {
        get {
            let stored = UserDefaults.standard.double(forKey: "\(prefix).capture.quickAccessAutoClose")
            return stored > 0 ? stored : 0
        }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.quickAccessAutoClose") }
    }

    /// Prompt for a file name before Save / auto-save after Capture.
    static var askForName: Bool {
        get { UserDefaults.standard.bool(forKey: "\(prefix).capture.askForName") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.askForName") }
    }

    // MARK: After-Capture actions (can combine)

    static var afterCaptureCopy: Bool {
        get { UserDefaults.standard.bool(forKey: "\(prefix).capture.after.copy") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.after.copy") }
    }

    static var afterCaptureOpenEditor: Bool {
        get { UserDefaults.standard.bool(forKey: "\(prefix).capture.after.editor") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.after.editor") }
    }

    static var afterCapturePin: Bool {
        get { UserDefaults.standard.bool(forKey: "\(prefix).capture.after.pin") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.after.pin") }
    }

    static var afterCaptureUpload: Bool {
        get { UserDefaults.standard.bool(forKey: "\(prefix).capture.after.upload") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.after.upload") }
    }

    static var afterCaptureSave: Bool {
        get { UserDefaults.standard.bool(forKey: "\(prefix).capture.after.save") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.after.save") }
    }

    /// Play a shutter sound when a Capture completes.
    static var playShutterSound: Bool {
        get { UserDefaults.standard.object(forKey: "\(prefix).capture.playShutterSound") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.playShutterSound") }
    }

    /// Convert exported pixels to sRGB before writing.
    static var convertToSRGB: Bool {
        get { UserDefaults.standard.bool(forKey: "\(prefix).capture.convertToSRGB") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.convertToSRGB") }
    }

    /// Allow `parcel://` URL scheme automation.
    static var urlSchemeEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "\(prefix).capture.urlSchemeEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.urlSchemeEnabled") }
    }

    /// Filename template tokens: `{date}`, `{time}`, `{month}`, `{index}`, `{app}`, `{window}`.
    static var fileNameTemplate: String {
        get {
            UserDefaults.standard.string(forKey: "\(prefix).capture.fileNameTemplate")
                ?? "Parcel {date} at {time}"
        }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.fileNameTemplate") }
    }

    static var fileNameIndex: Int {
        get { max(0, UserDefaults.standard.integer(forKey: "\(prefix).capture.fileNameIndex")) }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.fileNameIndex") }
    }

    /// When true, OCR joins recognized lines with spaces instead of newlines.
    static var ocrStripLineBreaks: Bool {
        get { UserDefaults.standard.bool(forKey: "\(prefix).capture.ocrStripLineBreaks") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.ocrStripLineBreaks") }
    }

    /// Downscale Retina Captures to 1× points for smaller files / sharing.
    static var scaleDownRetina: Bool {
        get { UserDefaults.standard.bool(forKey: "\(prefix).capture.scaleDownRetina") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.scaleDownRetina") }
    }

    /// Draw full-screen crosshairs under the cursor while selecting.
    static var showCrosshair: Bool {
        get { UserDefaults.standard.object(forKey: "\(prefix).capture.showCrosshair") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.showCrosshair") }
    }

    /// Show a loupe magnifier near the cursor while selecting.
    static var showMagnifier: Bool {
        get { UserDefaults.standard.object(forKey: "\(prefix).capture.showMagnifier") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.showMagnifier") }
    }

    /// Hide Finder desktop icons while capturing / recording (best-effort; may require non-sandbox).
    static var hideDesktopIcons: Bool {
        get { UserDefaults.standard.bool(forKey: "\(prefix).capture.hideDesktopIcons") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.hideDesktopIcons") }
    }

    /// Show the All-in-One mode strip on the Selection Overlay.
    static var showAllInOneBar: Bool {
        get { UserDefaults.standard.object(forKey: "\(prefix).capture.showAllInOneBar") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.showAllInOneBar") }
    }

    // MARK: Previous area

    static var hasPreviousArea: Bool {
        lastSelectionDisplayID != 0 && lastSelectionWidth > 1 && lastSelectionHeight > 1
    }

    static var lastSelectionDisplayID: CGDirectDisplayID {
        get { CGDirectDisplayID(UserDefaults.standard.integer(forKey: "\(prefix).capture.last.displayID")) }
        set { UserDefaults.standard.set(Int(newValue), forKey: "\(prefix).capture.last.displayID") }
    }

    static var lastSelectionX: Double {
        get { UserDefaults.standard.double(forKey: "\(prefix).capture.last.x") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.last.x") }
    }

    static var lastSelectionY: Double {
        get { UserDefaults.standard.double(forKey: "\(prefix).capture.last.y") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.last.y") }
    }

    static var lastSelectionWidth: Double {
        get { UserDefaults.standard.double(forKey: "\(prefix).capture.last.width") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.last.width") }
    }

    static var lastSelectionHeight: Double {
        get { UserDefaults.standard.double(forKey: "\(prefix).capture.last.height") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.last.height") }
    }

    static var lastSelectionRect: CGRect {
        CGRect(
            x: lastSelectionX,
            y: lastSelectionY,
            width: lastSelectionWidth,
            height: lastSelectionHeight
        )
    }

    static func rememberSelection(_ result: SelectionResult) {
        lastSelectionDisplayID = result.screen.id
        lastSelectionX = result.rectInPoints.origin.x
        lastSelectionY = result.rectInPoints.origin.y
        lastSelectionWidth = result.rectInPoints.width
        lastSelectionHeight = result.rectInPoints.height
    }

    // MARK: Last recording area

    static var hasPreviousRecordingArea: Bool {
        lastRecordingDisplayID != 0 && lastRecordingWidth > 1 && lastRecordingHeight > 1
    }

    static var lastRecordingDisplayID: CGDirectDisplayID {
        get { CGDirectDisplayID(UserDefaults.standard.integer(forKey: "\(prefix).capture.lastRec.displayID")) }
        set { UserDefaults.standard.set(Int(newValue), forKey: "\(prefix).capture.lastRec.displayID") }
    }

    static var lastRecordingX: Double {
        get { UserDefaults.standard.double(forKey: "\(prefix).capture.lastRec.x") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.lastRec.x") }
    }

    static var lastRecordingY: Double {
        get { UserDefaults.standard.double(forKey: "\(prefix).capture.lastRec.y") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.lastRec.y") }
    }

    static var lastRecordingWidth: Double {
        get { UserDefaults.standard.double(forKey: "\(prefix).capture.lastRec.width") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.lastRec.width") }
    }

    static var lastRecordingHeight: Double {
        get { UserDefaults.standard.double(forKey: "\(prefix).capture.lastRec.height") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).capture.lastRec.height") }
    }

    static func rememberRecordingSelection(displayID: CGDirectDisplayID, rect: CGRect) {
        lastRecordingDisplayID = displayID
        lastRecordingX = rect.origin.x
        lastRecordingY = rect.origin.y
        lastRecordingWidth = rect.width
        lastRecordingHeight = rect.height
    }
}

/// Builds Capture file names from the user template.
enum CaptureFileName {
    static func make(
        extension ext: String,
        appName: String? = nil,
        windowTitle: String? = nil,
        date: Date = Date()
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH.mm.ss"
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy-MM"

        var result = CapturePreferences.fileNameTemplate
        result = result.replacingOccurrences(of: "{date}", with: dateFormatter.string(from: date))
        result = result.replacingOccurrences(of: "{time}", with: timeFormatter.string(from: date))
        result = result.replacingOccurrences(of: "{month}", with: monthFormatter.string(from: date))
        result = result.replacingOccurrences(of: "{index}", with: String(CapturePreferences.fileNameIndex))
        result = result.replacingOccurrences(of: "{app}", with: sanitize(appName ?? "App"))
        result = result.replacingOccurrences(of: "{window}", with: sanitize(windowTitle ?? "Window"))
        CapturePreferences.fileNameIndex += 1

        let illegal = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let cleaned = result.components(separatedBy: illegal).joined(separator: "-")
        return "\(cleaned).\(ext)"
    }

    private static func sanitize(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled" : trimmed
    }
}
