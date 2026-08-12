import Foundation

/// After-Capture override for "Capture Area & ..." hotkeys that still respect preferences
/// when the dedicated action is layered on top of the default matrix.
enum CaptureIntent: Equatable {
    case standard
    case forceCopy
    case forceEditor
    case forcePin
    case forceSave
}

struct AfterCapturePreferences: Equatable {
    var useQuickAccess: Bool
    var copy: Bool
    var upload: Bool
    var save: Bool
    var pin: Bool
    var openEditor: Bool

    static var current: AfterCapturePreferences {
        AfterCapturePreferences(
            useQuickAccess: CapturePreferences.useQuickAccess,
            copy: CapturePreferences.afterCaptureCopy,
            upload: CapturePreferences.afterCaptureUpload,
            save: CapturePreferences.afterCaptureSave,
            pin: CapturePreferences.afterCapturePin,
            openEditor: CapturePreferences.afterCaptureOpenEditor
        )
    }
}

struct AfterCapturePlan: Equatable {
    var copy = false
    var upload = false
    var save = false
    var pin = false
    var openEditor = false
    var showQuickAccess = false

    static func make(preferences: AfterCapturePreferences, intent: CaptureIntent) -> AfterCapturePlan {
        var plan = AfterCapturePlan()
        plan.copy = preferences.copy || intent == .forceCopy
        plan.upload = preferences.upload
        plan.save = preferences.save || intent == .forceSave
        plan.pin = preferences.pin || intent == .forcePin
        plan.openEditor = preferences.openEditor || intent == .forceEditor

        guard !plan.openEditor else { return plan }

        let forcedOnly = intent == .forceCopy || intent == .forceSave || intent == .forcePin
        if preferences.useQuickAccess && !forcedOnly {
            plan.showQuickAccess = true
        } else if intent == .standard,
                  !preferences.pin,
                  !preferences.openEditor,
                  !preferences.useQuickAccess {
            plan.openEditor = true
        }
        return plan
    }
}
