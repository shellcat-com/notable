import Carbon.HIToolbox
import Foundation

/// Persisted global Capture hotkeys. Primary default: ⌘⇧2.
enum HotKeyPreferences {
    private static let keyCodeKey = "\(AppIdentity.defaultsPrefix).hotkey.keyCode"
    private static let modifiersKey = "\(AppIdentity.defaultsPrefix).hotkey.modifiers"

    struct Binding {
        let action: HotKeyManager.Action
        let keyCode: UInt32
        let modifiers: UInt32
        let isEnabled: Bool
    }

    static var keyCode: UInt32 {
        get {
            let stored = UserDefaults.standard.integer(forKey: keyCodeKey)
            return stored == 0 ? UInt32(kVK_ANSI_2) : UInt32(stored)
        }
        set { UserDefaults.standard.set(Int(newValue), forKey: keyCodeKey) }
    }

    static var modifiers: UInt32 {
        get {
            if UserDefaults.standard.object(forKey: modifiersKey) == nil {
                return UInt32(cmdKey | shiftKey)
            }
            return UInt32(UserDefaults.standard.integer(forKey: modifiersKey))
        }
        set { UserDefaults.standard.set(Int(newValue), forKey: modifiersKey) }
    }

    static var displayString: String {
        HotKeyDisplay.string(keyCode: keyCode, modifiers: modifiers)
    }

    /// Extra Capture Area & … shortcuts registered alongside the primary Capture shortcut.
    static var extraBindings: [Binding] {
        [
            Binding(
                action: .captureCopy,
                keyCode: UInt32(stored("copy.keyCode", default: kVK_ANSI_C)),
                modifiers: UInt32(stored("copy.modifiers", default: Int(cmdKey | shiftKey | optionKey))),
                isEnabled: bool("copy.enabled", default: true)
            ),
            Binding(
                action: .captureAnnotate,
                keyCode: UInt32(stored("annotate.keyCode", default: kVK_ANSI_A)),
                modifiers: UInt32(stored("annotate.modifiers", default: Int(cmdKey | shiftKey | optionKey))),
                isEnabled: bool("annotate.enabled", default: true)
            ),
            Binding(
                action: .capturePin,
                keyCode: UInt32(stored("pin.keyCode", default: kVK_ANSI_P)),
                modifiers: UInt32(stored("pin.modifiers", default: Int(cmdKey | shiftKey | optionKey))),
                isEnabled: bool("pin.enabled", default: true)
            ),
            Binding(
                action: .captureSave,
                keyCode: UInt32(stored("save.keyCode", default: kVK_ANSI_S)),
                modifiers: UInt32(stored("save.modifiers", default: Int(cmdKey | shiftKey | optionKey))),
                isEnabled: bool("save.enabled", default: false)
            ),
            Binding(
                action: .capturePrevious,
                keyCode: UInt32(stored("previous.keyCode", default: kVK_ANSI_5)),
                modifiers: UInt32(stored("previous.modifiers", default: Int(cmdKey | shiftKey))),
                isEnabled: bool("previous.enabled", default: true)
            ),
            Binding(
                action: .openClipboard,
                keyCode: UInt32(stored("clipboard.keyCode", default: kVK_ANSI_V)),
                modifiers: UInt32(stored("clipboard.modifiers", default: Int(cmdKey | shiftKey | optionKey))),
                isEnabled: bool("clipboard.enabled", default: false)
            ),
            Binding(
                action: .restoreClosed,
                keyCode: UInt32(stored("restore.keyCode", default: kVK_ANSI_Z)),
                modifiers: UInt32(stored("restore.modifiers", default: Int(cmdKey | shiftKey | optionKey))),
                isEnabled: bool("restore.enabled", default: true)
            ),
            Binding(
                action: .hideOverlays,
                keyCode: UInt32(stored("hide.keyCode", default: kVK_ANSI_H)),
                modifiers: UInt32(stored("hide.modifiers", default: Int(cmdKey | shiftKey | optionKey))),
                isEnabled: bool("hide.enabled", default: true)
            ),
            Binding(
                action: .annotateLast,
                keyCode: UInt32(stored("last.keyCode", default: kVK_ANSI_E)),
                modifiers: UInt32(stored("last.modifiers", default: Int(cmdKey | shiftKey | optionKey))),
                isEnabled: bool("last.enabled", default: false)
            ),
            Binding(
                action: .ocr,
                keyCode: UInt32(stored("ocr.keyCode", default: kVK_ANSI_T)),
                modifiers: UInt32(stored("ocr.modifiers", default: Int(cmdKey | shiftKey | optionKey))),
                isEnabled: bool("ocr.enabled", default: false)
            ),
        ]
    }

    static func resetToDefault() {
        keyCode = UInt32(kVK_ANSI_2)
        modifiers = UInt32(cmdKey | shiftKey)
    }

    /// Shortcuts that would steal macOS window / app chrome if rebound as Capture.
    static func isReservedSystemShortcut(keyCode: UInt32, modifiers: UInt32) -> Bool {
        let mods = modifiers & UInt32(cmdKey | shiftKey | optionKey | controlKey)
        guard mods == UInt32(cmdKey) else { return false }
        switch Int(keyCode) {
        case kVK_ANSI_W, kVK_ANSI_Q, kVK_ANSI_H, kVK_ANSI_M, kVK_ANSI_Comma:
            return true
        default:
            return false
        }
    }

    private static func stored(_ suffix: String, default defaultValue: Int) -> Int {
        let key = "\(AppIdentity.defaultsPrefix).hotkey.\(suffix)"
        if UserDefaults.standard.object(forKey: key) == nil { return defaultValue }
        return UserDefaults.standard.integer(forKey: key)
    }

    private static func bool(_ suffix: String, default defaultValue: Bool) -> Bool {
        let key = "\(AppIdentity.defaultsPrefix).hotkey.\(suffix)"
        if UserDefaults.standard.object(forKey: key) == nil { return defaultValue }
        return UserDefaults.standard.bool(forKey: key)
    }
}

/// Human-readable shortcut labels for Preferences and the marketing site.
enum HotKeyDisplay {
    static func string(keyCode: UInt32, modifiers: UInt32) -> String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        parts.append(keyLabel(for: keyCode))
        return parts.joined()
    }

    private static func keyLabel(for keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_Space: return "Space"
        case kVK_Return: return "Return"
        case kVK_Escape: return "Esc"
        default: return "Key \(keyCode)"
        }
    }
}
