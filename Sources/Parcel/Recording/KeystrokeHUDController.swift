import AppKit
import Carbon.HIToolbox
import SwiftUI

/// Floating dark pill that shows the latest keystroke while recording.
@MainActor
final class KeystrokeHUDController {

    private var window: NSPanel?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var hideWorkItem: DispatchWorkItem?
    private var hosting: NSHostingView<KeystrokeHUDView>?

    func start() {
        guard RecordingPreferences.showsKeystrokes else { return }
        stop()
        presentWindow()
        installMonitors()
    }

    func stop() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        window?.orderOut(nil)
        window = nil
        hosting = nil
    }

    // MARK: Private

    private func presentWindow() {
        let size = CGSize(width: 420, height: 56)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .screenSaver
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isReleasedWhenClosed = false

        let root = KeystrokeHUDView(label: "")
        let view = NSHostingView(rootView: root)
        view.frame = NSRect(origin: .zero, size: size)
        panel.contentView = view
        hosting = view
        window = panel
        positionOnScreen()
        // Stay hidden until the first key.
        panel.alphaValue = 0
        panel.orderFrontRegardless()
    }

    private func installMonitors() {
        let handler: (NSEvent) -> Void = { [weak self] event in
            Task { @MainActor in self?.handle(event) }
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.keyDown, .flagsChanged],
            handler: handler
        )
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    private func handle(_ event: NSEvent) {
        guard let label = KeystrokeHUDLabel.label(
            for: event,
            commandOnly: RecordingPreferences.keystrokesCommandOnly
        ), !label.isEmpty else { return }
        show(label: label)
    }

    private func show(label: String) {
        guard let window, let hosting else { return }
        hosting.rootView = KeystrokeHUDView(label: label)
        positionOnScreen()
        window.alphaValue = 1
        window.orderFrontRegardless()

        hideWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.25
                self?.window?.animator().alphaValue = 0
            }
        }
        hideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4, execute: work)
    }

    private func positionOnScreen() {
        guard let window else { return }
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let size = window.frame.size
        let margin: CGFloat = 28
        let origin: CGPoint
        switch RecordingHUDPosition.current {
        case .bottomCenter:
            origin = CGPoint(x: screen.midX - size.width / 2, y: screen.minY + margin)
        case .bottomLeading:
            origin = CGPoint(x: screen.minX + margin, y: screen.minY + margin)
        case .bottomTrailing:
            origin = CGPoint(x: screen.maxX - size.width - margin, y: screen.minY + margin)
        case .topCenter:
            origin = CGPoint(x: screen.midX - size.width / 2, y: screen.maxY - size.height - margin)
        }
        window.setFrameOrigin(origin)
    }
}

/// Builds the keystroke HUD shortcut string (⌘⇧A, Return, etc.) without requiring a live event monitor.
enum KeystrokeHUDLabel {
    static func label(for event: NSEvent, commandOnly: Bool) -> String? {
        label(
            eventType: event.type,
            keyCode: event.keyCode,
            charactersIgnoringModifiers: event.charactersIgnoringModifiers,
            modifierFlags: event.modifierFlags,
            commandOnly: commandOnly
        )
    }

    static func label(
        eventType: NSEvent.EventType,
        keyCode: UInt16,
        charactersIgnoringModifiers: String?,
        modifierFlags: NSEvent.ModifierFlags,
        commandOnly: Bool
    ) -> String? {
        if eventType == .flagsChanged {
            let mods = modifierSymbols(modifierFlags)
            return mods.isEmpty ? nil : mods
        }

        guard eventType == .keyDown else { return nil }
        // Skip pure modifier presses already handled by flagsChanged.
        if keyCode == UInt16(kVK_Shift)
            || keyCode == UInt16(kVK_RightShift)
            || keyCode == UInt16(kVK_Control)
            || keyCode == UInt16(kVK_RightControl)
            || keyCode == UInt16(kVK_Option)
            || keyCode == UInt16(kVK_RightOption)
            || keyCode == UInt16(kVK_Command)
            || keyCode == UInt16(kVK_RightCommand)
        {
            return nil
        }

        let mods = modifierSymbols(modifierFlags)
        let key = keyName(keyCode: keyCode, charactersIgnoringModifiers: charactersIgnoringModifiers)
        guard !key.isEmpty else { return nil }

        // Prefer showing command-combo shortcuts; still show plain keys for tutorials.
        if commandOnly {
            let hasCommand = modifierFlags.contains(.command)
                || modifierFlags.contains(.control)
                || modifierFlags.contains(.option)
            guard hasCommand else { return nil }
        }
        return mods + key
    }

    private static func modifierSymbols(_ flags: NSEvent.ModifierFlags) -> String {
        var parts = ""
        if flags.contains(.control) { parts += "⌃" }
        if flags.contains(.option) { parts += "⌥" }
        if flags.contains(.shift) { parts += "⇧" }
        if flags.contains(.command) { parts += "⌘" }
        return parts
    }

    private static func keyName(keyCode: UInt16, charactersIgnoringModifiers: String?) -> String {
        switch Int(keyCode) {
        case kVK_Return, kVK_ANSI_KeypadEnter: return "↩"
        case kVK_Escape: return "Esc"
        case kVK_Delete: return "⌫"
        case kVK_ForwardDelete: return "⌦"
        case kVK_Tab: return "⇥"
        case kVK_Space: return "Space"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        default:
            if let chars = charactersIgnoringModifiers?.uppercased(), !chars.isEmpty {
                return chars
            }
            return ""
        }
    }
}

private struct KeystrokeHUDView: View {
    let label: String

    var body: some View {
        Group {
            if label.isEmpty {
                Color.clear
            } else {
                Text(label)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.black.opacity(0.78))
                    )
                    .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
