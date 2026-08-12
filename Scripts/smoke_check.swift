#!/usr/bin/env swift
import Foundation

// Non-GUI smoke checks for Parcel core modules logic (run from repo root after build).
// Validates identity migration keys, output formats, and bundle structure.

enum Smoke {
    static func run() {
        var passed = 0
        var failed = 0

        func check(_ name: String, _ ok: Bool) {
            if ok { passed += 1; print("PASS: \(name)") }
            else { failed += 1; print("FAIL: \(name)") }
        }

        let appPath = ProcessInfo.processInfo.environment["PARCEL_APP_PATH"]
            ?? ".derivedData/Build/Products/Debug/Parcel.app"
        let infoPlist = "\(appPath)/Contents/Info.plist"
        check("Parcel.app exists", FileManager.default.fileExists(atPath: appPath))
        check("Info.plist exists", FileManager.default.fileExists(atPath: infoPlist))

        if let plist = NSDictionary(contentsOfFile: infoPlist) {
            check("Display name is Parcel", plist["CFBundleDisplayName"] as? String == "Parcel")
            check("Bundle ID is dev.parable.Parcel", plist["CFBundleIdentifier"] as? String == "dev.parable.Parcel")
            check("Mic usage string present", (plist["NSMicrophoneUsageDescription"] as? String)?.isEmpty == false)
            check("Sparkle feed URL present", (plist["SUFeedURL"] as? String)?.contains("appcast") == true)
            check("Menu bar app (LSUIElement)", plist["LSUIElement"] as? Bool == true)
        } else {
            check("Info.plist readable", false)
        }

        // ad-hoc builds may not embed profile; check entitlements via codesign
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        task.arguments = ["-d", "--entitlements", ":-", appPath]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        try? task.run()
        task.waitUntilExit()
        let entData = pipe.fileHandleForReading.readDataToEndOfFile()
        if let entStr = String(data: entData, encoding: .utf8) {
            check("Sandbox enabled", entStr.contains("app-sandbox") && entStr.contains("<true/>"))
            check("User-selected read-write", entStr.contains("user-selected.read-write"))
        } else {
            check("Entitlements readable", false)
        }

        let iconPath = "\(appPath)/Contents/Resources/AppIcon.icns"
        let assetsIcon = "\(appPath)/Contents/Resources/Assets.car"
        check("Has AppIcon or asset catalog", FileManager.default.fileExists(atPath: iconPath) || FileManager.default.fileExists(atPath: assetsIcon))

        check("Sparkle framework embedded", FileManager.default.fileExists(atPath: "\(appPath)/Contents/Frameworks/Sparkle.framework"))

        let websiteOutputs = ["Website/dist/index.html", "Website/out/index.html", "Website/.next/BUILD_ID"]
        check("Website built", websiteOutputs.contains { FileManager.default.fileExists(atPath: $0) })

        let appcast = "Website/public/appcast.xml"
        check("Sparkle appcast exists", FileManager.default.fileExists(atPath: appcast))

        print("\n--- \(passed) passed, \(failed) failed ---")
        if failed > 0 { exit(1) }
    }
}

Smoke.run()
