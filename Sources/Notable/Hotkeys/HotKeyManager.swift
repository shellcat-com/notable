import AppKit
import Carbon.HIToolbox

/// Registers a single global hotkey via the Carbon Hot Key API.
///
/// `RegisterEventHotKey` is the mechanism used by KeyboardShortcuts/HotKey. Unlike a `CGEventTap`
/// it requires **no** Accessibility/Input Monitoring permission for a plain modifier+key combo,
/// which removes a whole class of first-run permission dead-ends. The Carbon callback is a C
/// function pointer that can't capture context, so we thread `self` through `userData`.
final class HotKeyManager {

    /// Fires on the main queue when the hotkey is pressed.
    var onHotKey: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let signature: OSType = 0x4E4F5442 // 'NOTB'

    /// Default capture shortcut: ⌘⇧2 (⌘⇧3/4/5 belong to the macOS screenshot service).
    func registerDefault() {
        register(keyCode: UInt32(kVK_ANSI_2), modifiers: UInt32(cmdKey | shiftKey))
    }

    func register(keyCode: UInt32, modifiers: UInt32) {
        installHandlerIfNeeded()
        unregisterHotKey()

        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: signature, id: 1)
        let status = RegisterEventHotKey(
            keyCode, modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &ref
        )
        if status == noErr {
            hotKeyRef = ref
        } else {
            NSLog("Notable: RegisterEventHotKey failed (status \(status))")
        }
    }

    func unregisterAll() {
        unregisterHotKey()
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }

    // MARK: Private

    private func installHandlerIfNeeded() {
        guard handlerRef == nil else { return }
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, _, userData -> OSStatus in
                guard let userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { manager.onHotKey?() }
                return noErr
            },
            1, &eventType, selfPtr, &handlerRef
        )
    }

    private func unregisterHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
}
