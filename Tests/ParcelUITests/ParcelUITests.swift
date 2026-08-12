import AppKit
import CoreGraphics
import XCTest

/// Parcel QA harness. Fails loudly when Screen Recording TCC does not match the current binary.
final class ParcelUITests: XCTestCase {

    private var app: XCUIApplication!
    private let evidence = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("qa-evidence", isDirectory: true)

    override func setUpWithError() throws {
        continueAfterFailure = false
        try FileManager.default.createDirectory(at: evidence, withIntermediateDirectories: true)
        app = XCUIApplication(bundleIdentifier: "dev.parable.Parcel")
        app.launch()
        sleep(2)
        dismissBlockingAlerts()
        dismissWelcomeIfPresent()
    }

    override func tearDownWithError() throws {
        app?.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        app?.terminate()
    }

    private func snap(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        try? shot.pngRepresentation.write(to: evidence.appendingPathComponent("\(name).png"))
    }

    private func dismissBlockingAlerts() {
        let ok = app.buttons["OK"]
        if ok.waitForExistence(timeout: 2) { ok.click(); sleep(1) }
    }

    private func dismissWelcomeIfPresent() {
        let welcome = app.windows["Welcome to Parcel"]
        guard welcome.waitForExistence(timeout: 2) else { return }
        snap("00-welcome")
        for _ in 0..<4 {
            if app.buttons["Get Started"].exists { app.buttons["Get Started"].click(); break }
            if app.buttons["Continue"].exists { app.buttons["Continue"].click() }
            else if app.buttons["Skip"].exists { app.buttons["Skip"].click() }
            Thread.sleep(forTimeInterval: 0.5)
        }
    }

    private func openMenuBarMenu() {
        dismissBlockingAlerts()
        let item = app.statusItems.element(boundBy: 0)
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        if item.isHittable {
            item.click()
        } else if !clickSystemStatusItem() {
            clickMenuBarCoordinateFallback(from: item.frame)
        }
        XCTAssertTrue(
            app.menuItems["Capture Region"].waitForExistence(timeout: 5),
            "Parcel menu did not open from the menu bar status item."
        )
    }

    private func clickSystemStatusItem() -> Bool {
        let systemUI = XCUIApplication(bundleIdentifier: "com.apple.systemuiserver")
        let candidates = [
            systemUI.menuBars.statusItems["MenuBarIcon"],
            systemUI.statusItems["MenuBarIcon"],
            systemUI.statusItems.element(boundBy: 0),
        ]

        for candidate in candidates where candidate.exists {
            if candidate.isHittable {
                candidate.click()
            } else {
                postMouseClick(at: clampedMenuPoint(from: candidate.frame))
            }
            if app.menuItems["Capture Region"].waitForExistence(timeout: 2) { return true }
        }
        return false
    }

    private func clickMenuBarCoordinateFallback(from frame: CGRect) {
        let screen = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let x = min(max(finite(frame.midX, fallback: screen.maxX - 20), screen.minX + 12), screen.maxX - 12)
        for y in [screen.maxY - 12, screen.minY + 12] {
            postMouseClick(at: CGPoint(x: x, y: y))
            if app.menuItems["Capture Region"].waitForExistence(timeout: 2) { return }
        }
    }

    private func clampedMenuPoint(from frame: CGRect) -> CGPoint {
        let screen = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1728, height: 1117)
        return CGPoint(
            x: min(max(finite(frame.midX, fallback: screen.maxX - 20), screen.minX + 12), screen.maxX - 12),
            y: min(max(finite(frame.midY, fallback: screen.maxY - 12), screen.minY + 12), screen.maxY - 12)
        )
    }

    private func finite(_ value: CGFloat, fallback: CGFloat) -> CGFloat {
        value.isFinite ? value : fallback
    }

    private func postMouseClick(at point: CGPoint) {
        let source = CGEventSource(stateID: .hidSystemState)
        CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseDown,
            mouseCursorPosition: point,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
        usleep(50_000)
        CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseUp,
            mouseCursorPosition: point,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
    }

    private func clickMenuItem(_ title: String) {
        let item = app.menuItems[title]
        XCTAssertTrue(item.waitForExistence(timeout: 5), "Missing: \(title)")
        item.click()
    }

    private func assertPreferencesDidNotOpen(file: StaticString = #file, line: UInt = #line) {
        let prefs = app.windows["Parcel Preferences"]
        if prefs.waitForExistence(timeout: 2) {
            snap("FAIL-preferences-instead-of-capture")
            XCTFail(
                "Capture opened Preferences — Screen Recording TCC does not match this build. " +
                "Remove Parcel in System Settings → Screen Recording, click +, choose the current Parcel.app, quit & reopen.",
                file: file, line: line
            )
        }
    }

    // MARK: - Core

    func test01AppLaunches() throws {
        snap("01-app-launched")
    }

    func test02MenuBarExtraOpensWithExpectedItems() throws {
        openMenuBarMenu()
        snap("02-menu-open")
        for title in ["Capture Region", "Capture All Displays", "Preferences…", "Capture History…"] {
            XCTAssertTrue(app.menuItems[title].exists)
        }
    }

    func test03CaptureRegionShowsOverlay() throws {
        openMenuBarMenu()
        clickMenuItem("Capture Region")
        sleep(2)
        snap("03-after-capture-region")
        assertPreferencesDidNotOpen()
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        sleep(1)
        snap("03-after-esc")
    }

    func test04PreferencesPermissionStatus() throws {
        openMenuBarMenu()
        clickMenuItem("Preferences…")
        sleep(2)
        snap("04-preferences")
        let granted = app.staticTexts["Granted"].waitForExistence(timeout: 5)
        if !granted {
            snap("04-FAIL-permission-not-granted")
            XCTFail("Preferences still shows Screen Recording as not granted for this binary.")
        }
    }

    func test05CaptureAllDisplaysOpensEditor() throws {
        openMenuBarMenu()
        clickMenuItem("Capture All Displays")
        sleep(4)
        snap("05-after-all-displays")
        assertPreferencesDidNotOpen()
        let editor = app.windows.containing(.staticText, identifier: "Create").firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 10), "Editor toolbar should appear")
    }

    func test06CaptureHistoryOpens() throws {
        openMenuBarMenu()
        clickMenuItem("Capture History…")
        sleep(1)
        snap("06-capture-history")
        XCTAssertTrue(app.windows.containing(.staticText, identifier: "Capture History").firstMatch.waitForExistence(timeout: 5))
    }
}
