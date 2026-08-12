import AppKit
import Foundation

/// Best-effort hide/show of Finder desktop icons for a cleaner Capture or recording.
/// Uses `defaults` + `killall Finder`. Works in non-sandboxed Debug builds; Release sandbox
/// may block the child processes — failures are ignored so Capture still proceeds.
@MainActor
enum DesktopIconHider {
    private static var sessionHidden = false
    private static var previousCreateDesktop: Bool?

    /// Hide desktop icons if the preference is on and they are currently visible.
    static func beginSessionIfNeeded() {
        guard CapturePreferences.hideDesktopIcons else { return }
        guard !sessionHidden else { return }
        previousCreateDesktop = readCreateDesktop()
        guard previousCreateDesktop != false else { return }
        if setCreateDesktop(false) {
            sessionHidden = true
            // Give Finder a beat to redraw without icons before freeze.
            Thread.sleep(forTimeInterval: 0.35)
        }
    }

    /// Restore icons if this session hid them.
    static func endSession() {
        guard sessionHidden else { return }
        sessionHidden = false
        let restore = previousCreateDesktop ?? true
        previousCreateDesktop = nil
        _ = setCreateDesktop(restore)
    }

    private static func readCreateDesktop() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        task.arguments = ["read", "com.apple.finder", "CreateDesktop"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if text == "0" || text.lowercased() == "false" { return false }
            return true
        } catch {
            return true
        }
    }

    @discardableResult
    private static func setCreateDesktop(_ visible: Bool) -> Bool {
        let write = Process()
        write.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        write.arguments = [
            "write", "com.apple.finder", "CreateDesktop", "-bool", visible ? "true" : "false",
        ]
        write.standardOutput = Pipe()
        write.standardError = Pipe()
        do {
            try write.run()
            write.waitUntilExit()
            guard write.terminationStatus == 0 else { return false }
        } catch {
            return false
        }

        let kill = Process()
        kill.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        kill.arguments = ["Finder"]
        kill.standardOutput = Pipe()
        kill.standardError = Pipe()
        do {
            try kill.run()
            kill.waitUntilExit()
            return true
        } catch {
            return false
        }
    }
}
