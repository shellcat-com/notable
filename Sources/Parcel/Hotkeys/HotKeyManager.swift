import AppKit
import Carbon.HIToolbox

/// Registers multiple global hotkeys via the Carbon Hot Key API.
///
/// `RegisterEventHotKey` needs **no** Accessibility permission for plain modifier+key combos.
final class HotKeyManager {

    enum Action: UInt32 {
        case captureRegion = 1
        case captureCopy = 2
        case captureAnnotate = 3
        case capturePin = 4
        case captureSave = 5
        case capturePrevious = 6
        case openClipboard = 7
        case restoreClosed = 8
        case hideOverlays = 9
        case annotateLast = 10
        case ocr = 11
    }

    /// Fires on the main queue when a registered hotkey is pressed.
    var onAction: ((Action) -> Void)?

    /// Legacy single-callback used when only the primary Capture hotkey matters.
    var onHotKey: (() -> Void)? {
        didSet {
            // Keep backward compatibility: primary action also invokes onHotKey.
        }
    }

    private var hotKeyRefs: [Action: EventHotKeyRef] = [:]
    private var handlerRef: EventHandlerRef?
    private let signature: OSType = 0x5052434C // 'PRCL'

    func registerDefault() {
        installHandlerIfNeeded()
        unregisterHotKeys()

        register(
            action: .captureRegion,
            keyCode: HotKeyPreferences.keyCode,
            modifiers: HotKeyPreferences.modifiers
        )

        for binding in HotKeyPreferences.extraBindings {
            guard binding.isEnabled else { continue }
            register(action: binding.action, keyCode: binding.keyCode, modifiers: binding.modifiers)
        }
    }

    func unregisterAll() {
        unregisterHotKeys()
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }

    // MARK: Private

    private func register(action: Action, keyCode: UInt32, modifiers: UInt32) {
        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: signature, id: action.rawValue)
        let status = RegisterEventHotKey(
            keyCode, modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &ref
        )
        if status == noErr, let ref {
            hotKeyRefs[action] = ref
        } else {
            NSLog("Parcel: RegisterEventHotKey failed for \(action) (status \(status))")
        }
    }

    private func installHandlerIfNeeded() {
        guard handlerRef == nil else { return }
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, userData -> OSStatus in
                guard let userData, let event else { return noErr }
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                let action = Action(rawValue: hotKeyID.id) ?? .captureRegion
                DispatchQueue.main.async {
                    manager.onAction?(action)
                    if action == .captureRegion {
                        manager.onHotKey?()
                    }
                }
                return noErr
            },
            1, &eventType, selfPtr, &handlerRef
        )
    }

    private func unregisterHotKeys() {
        for (_, ref) in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
    }
}
