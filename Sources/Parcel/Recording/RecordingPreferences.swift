import Foundation
import CoreMedia

enum RecordingFPS: Int, CaseIterable, Identifiable {
    case fps30 = 30
    case fps60 = 60
    case fps120 = 120

    var id: Int { rawValue }

    var label: String { "\(rawValue) fps" }

    var frameInterval: CMTime {
        CMTime(value: 1, timescale: CMTimeScale(rawValue))
    }

    private static let storageKey = "\(AppIdentity.defaultsPrefix).recording.fps"

    static var current: RecordingFPS {
        get {
            let stored = UserDefaults.standard.integer(forKey: storageKey)
            return RecordingFPS(rawValue: stored) ?? .fps60
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: storageKey) }
    }
}

enum RecordingMaxResolution: String, CaseIterable, Identifiable {
    case native
    case p1080
    case p720
    case p480

    var id: String { rawValue }

    var label: String {
        switch self {
        case .native: return "Native"
        case .p1080: return "1080p"
        case .p720: return "720p"
        case .p480: return "480p"
        }
    }

    /// Longest edge cap in pixels; nil = uncapped.
    var maxLongEdge: Int? {
        switch self {
        case .native: return nil
        case .p1080: return 1920
        case .p720: return 1280
        case .p480: return 854
        }
    }

    private static let key = "\(AppIdentity.defaultsPrefix).recording.maxResolution"

    static var current: RecordingMaxResolution {
        get {
            let raw = UserDefaults.standard.string(forKey: key) ?? ""
            return RecordingMaxResolution(rawValue: raw) ?? .native
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: key) }
    }
}

enum RecordingHUDPosition: String, CaseIterable, Identifiable {
    case bottomCenter, bottomLeading, bottomTrailing, topCenter

    var id: String { rawValue }

    var label: String {
        switch self {
        case .bottomCenter: return "Bottom center"
        case .bottomLeading: return "Bottom left"
        case .bottomTrailing: return "Bottom right"
        case .topCenter: return "Top center"
        }
    }

    private static let key = "\(AppIdentity.defaultsPrefix).recording.hudPosition"

    static var current: RecordingHUDPosition {
        get {
            let raw = UserDefaults.standard.string(forKey: key) ?? ""
            return RecordingHUDPosition(rawValue: raw) ?? .bottomCenter
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: key) }
    }
}

/// Toggleable recording behavior.
enum RecordingPreferences {
    private static let prefix = AppIdentity.defaultsPrefix

    static var showsCursor: Bool {
        get { UserDefaults.standard.object(forKey: "\(prefix).recording.showsCursor") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).recording.showsCursor") }
    }

    static var capturesMicrophone: Bool {
        get { UserDefaults.standard.object(forKey: "\(prefix).recording.capturesMicrophone") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).recording.capturesMicrophone") }
    }

    static var showsMouseClicks: Bool {
        get { UserDefaults.standard.object(forKey: "\(prefix).recording.showsMouseClicks") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).recording.showsMouseClicks") }
    }

    /// Floating keystroke HUD while recording (dark pill, bottom-center).
    static var showsKeystrokes: Bool {
        get { UserDefaults.standard.object(forKey: "\(prefix).recording.showsKeystrokes") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).recording.showsKeystrokes") }
    }

    /// When true, only show shortcuts that include ⌘ / ⌃ / ⌥ (not every letter).
    static var keystrokesCommandOnly: Bool {
        get { UserDefaults.standard.bool(forKey: "\(prefix).recording.keystrokesCommandOnly") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).recording.keystrokesCommandOnly") }
    }

    /// Circular webcam PiP during recording (off by default).
    static var showsWebcam: Bool {
        get { UserDefaults.standard.bool(forKey: "\(prefix).recording.showsWebcam") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).recording.showsWebcam") }
    }

    /// Best-effort Focus / Do Not Disturb while recording.
    static var enableDoNotDisturb: Bool {
        get { UserDefaults.standard.bool(forKey: "\(prefix).recording.enableDoNotDisturb") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).recording.enableDoNotDisturb") }
    }

    /// Countdown seconds before recording starts (0 = none).
    static var countdownSeconds: Double {
        get { UserDefaults.standard.double(forKey: "\(prefix).recording.countdown") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).recording.countdown") }
    }

    /// Record audio as mono.
    static var recordMonoAudio: Bool {
        get { UserDefaults.standard.bool(forKey: "\(prefix).recording.mono") }
        set { UserDefaults.standard.set(newValue, forKey: "\(prefix).recording.mono") }
    }
}
