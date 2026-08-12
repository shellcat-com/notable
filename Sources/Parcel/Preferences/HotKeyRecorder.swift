import AppKit
import Carbon.HIToolbox
import SwiftUI

/// Captures the next key-down event as a global hotkey binding.
struct HotKeyRecorder: View {
    @Binding var keyCode: UInt32
    @Binding var modifiers: UInt32
    @State private var isRecording = false

    var body: some View {
        HStack {
            Text(isRecording ? "Press a shortcut…" : HotKeyDisplay.string(keyCode: keyCode, modifiers: modifiers))
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(isRecording ? "Cancel" : "Record…") {
                isRecording.toggle()
                if isRecording { installMonitor() }
            }
            if !isRecording {
                Button("Reset") { HotKeyPreferences.resetToDefault(); reload() }
            }
        }
        .onDisappear { removeMonitor() }
    }

    private static var monitor: Any?

    private func reload() {
        keyCode = HotKeyPreferences.keyCode
        modifiers = HotKeyPreferences.modifiers
    }

    private func installMonitor() {
        removeMonitor()
        Self.monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isRecording else { return event }
            let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
            guard !flags.isEmpty else { return nil }
            var carbonMods: UInt32 = 0
            if flags.contains(.control) { carbonMods |= UInt32(controlKey) }
            if flags.contains(.option) { carbonMods |= UInt32(optionKey) }
            if flags.contains(.shift) { carbonMods |= UInt32(shiftKey) }
            if flags.contains(.command) { carbonMods |= UInt32(cmdKey) }
            let code = UInt32(event.keyCode)
            // Reject bare ⌘W / ⌘Q / ⌘, — they collide with Close / Quit / Preferences.
            if HotKeyPreferences.isReservedSystemShortcut(keyCode: code, modifiers: carbonMods) {
                NSSound.beep()
                return nil
            }
            keyCode = code
            modifiers = carbonMods
            HotKeyPreferences.keyCode = keyCode
            HotKeyPreferences.modifiers = modifiers
            isRecording = false
            removeMonitor()
            NotificationCenter.default.post(name: .hotKeyPreferencesDidChange, object: nil)
            return nil
        }
    }

    private func removeMonitor() {
        if let monitor = Self.monitor {
            NSEvent.removeMonitor(monitor)
            Self.monitor = nil
        }
    }
}

extension Notification.Name {
    static let hotKeyPreferencesDidChange = Notification.Name("dev.parable.hotKeyPreferencesDidChange")
}
