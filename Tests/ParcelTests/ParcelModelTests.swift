import AppKit
import AVFoundation
import AudioToolbox
import Carbon.HIToolbox
import CoreImage
import CoreVideo
import ImageIO
import ScreenCaptureKit
import UniformTypeIdentifiers
import XCTest
@testable import Parcel

@MainActor
final class ParcelModelTests: XCTestCase {
    func testOutputFormatsMatchClaimedReleaseFormats() {
        XCTAssertEqual(OutputFormat.allCases.map(\.rawValue), ["png", "jpeg", "heic", "tiff", "webp"])
        XCTAssertEqual(OutputFormat.jpeg.fileExtension, "jpg")
        XCTAssertEqual(OutputFormat.webp.fileExtension, "webp")
        XCTAssertEqual(OutputFormat.webp.contentType.preferredFilenameExtension, "webp")
        XCTAssertFalse(OutputFormat.webp.usesImageIO)
        XCTAssertNil(OutputFormat.webp.bitmapType)
    }

    func testToolInventoryMatchesClaimedToolbar() {
        XCTAssertEqual(
            Tool.allCases.map(\.label),
            [
                "Select", "Arrow", "Rectangle", "Ellipse", "Text", "Pencil", "Censor",
                "Number", "Stamp", "Highlighter", "Measure", "Spotlight", "Loupe", "Eyedropper",
            ]
        )
        XCTAssertEqual(Tool.allCases.count, 14)
        XCTAssertEqual(Tool.allCases.filter(\.isUtility).map(\.label), ["Loupe", "Eyedropper"])
        XCTAssertEqual(ArrowStyle.allCases.map(\.label), ["Arrow", "Open Head", "Double", "Curved", "Elbow"])
        XCTAssertEqual(CensorMode.allCases.map(\.label), ["Blur", "Pixelate", "Solid", "Erase"])
    }

    func testURLSchemeActionsCoverParityRoutes() throws {
        XCTAssertEqual(
            ParcelURLRouter.action(for: try XCTUnwrap(URL(string: "parcel://capture/region"))),
            .region
        )
        XCTAssertEqual(
            ParcelURLRouter.action(
                for: try XCTUnwrap(URL(string: "parcel://capture/region?x=10&y=20&w=30&h=40&display=99"))
            ),
            .area(CGRect(x: 10, y: 20, width: 30, height: 40), 99)
        )
        XCTAssertEqual(
            ParcelURLRouter.action(for: try XCTUnwrap(URL(string: "parcel://capture/previous"))),
            .previous
        )
        XCTAssertEqual(
            ParcelURLRouter.action(for: try XCTUnwrap(URL(string: "parcel://capture/scroll"))),
            .scroll
        )
        XCTAssertEqual(
            ParcelURLRouter.action(for: try XCTUnwrap(URL(string: "parcel://open/clipboard"))),
            .openClipboard
        )
        XCTAssertEqual(
            ParcelURLRouter.action(for: try XCTUnwrap(URL(string: "parcel://restore"))),
            .restoreRecentlyClosed
        )
        XCTAssertEqual(
            ParcelURLRouter.action(for: try XCTUnwrap(URL(string: "parcel://overlays/hide"))),
            .hideOverlays
        )
        XCTAssertNil(ParcelURLRouter.action(for: try XCTUnwrap(URL(string: "https://parcel.parable.dev"))))
    }

    func testAfterCapturePlanCoversPreferenceMatrixAndForcedIntents() {
        let quickAccessDefaults = AfterCapturePreferences(
            useQuickAccess: true,
            copy: false,
            upload: false,
            save: false,
            pin: false,
            openEditor: false
        )
        XCTAssertEqual(
            AfterCapturePlan.make(preferences: quickAccessDefaults, intent: .standard),
            AfterCapturePlan(showQuickAccess: true)
        )

        let editorFallback = AfterCapturePreferences(
            useQuickAccess: false,
            copy: false,
            upload: false,
            save: false,
            pin: false,
            openEditor: false
        )
        XCTAssertEqual(
            AfterCapturePlan.make(preferences: editorFallback, intent: .standard),
            AfterCapturePlan(openEditor: true)
        )

        let allActions = AfterCapturePreferences(
            useQuickAccess: true,
            copy: true,
            upload: true,
            save: true,
            pin: true,
            openEditor: true
        )
        XCTAssertEqual(
            AfterCapturePlan.make(preferences: allActions, intent: .standard),
            AfterCapturePlan(copy: true, upload: true, save: true, pin: true, openEditor: true)
        )

        XCTAssertEqual(
            AfterCapturePlan.make(preferences: quickAccessDefaults, intent: .forceCopy),
            AfterCapturePlan(copy: true)
        )
        XCTAssertEqual(
            AfterCapturePlan.make(preferences: quickAccessDefaults, intent: .forceSave),
            AfterCapturePlan(save: true)
        )
        XCTAssertEqual(
            AfterCapturePlan.make(preferences: quickAccessDefaults, intent: .forcePin),
            AfterCapturePlan(pin: true)
        )
        XCTAssertEqual(
            AfterCapturePlan.make(preferences: quickAccessDefaults, intent: .forceEditor),
            AfterCapturePlan(openEditor: true)
        )
    }

    func testCapturePreferencesPersistDocumentedDefaultsAndToggles() {
        let prefix = AppIdentity.defaultsPrefix
        let keys = [
            "\(prefix).capture.useQuickAccess",
            "\(prefix).capture.quickAccessAutoClose",
            "\(prefix).capture.askForName",
            "\(prefix).capture.after.copy",
            "\(prefix).capture.after.editor",
            "\(prefix).capture.after.pin",
            "\(prefix).capture.after.upload",
            "\(prefix).capture.after.save",
            "\(prefix).capture.playShutterSound",
            "\(prefix).capture.convertToSRGB",
            "\(prefix).capture.urlSchemeEnabled",
            "\(prefix).capture.fileNameTemplate",
            "\(prefix).capture.fileNameIndex",
            "\(prefix).capture.ocrStripLineBreaks",
            "\(prefix).capture.scaleDownRetina",
            "\(prefix).capture.showCrosshair",
            "\(prefix).capture.showMagnifier",
            "\(prefix).capture.hideDesktopIcons",
            "\(prefix).capture.showAllInOneBar",
        ]
        let defaults = UserDefaults.standard
        let previousValues: [(String, Any?)] = keys.map { ($0, defaults.object(forKey: $0)) }
        defer {
            for (key, value) in previousValues {
                if let value {
                    defaults.set(value, forKey: key)
                } else {
                    defaults.removeObject(forKey: key)
                }
            }
        }

        keys.forEach { defaults.removeObject(forKey: $0) }

        XCTAssertTrue(CapturePreferences.useQuickAccess)
        XCTAssertEqual(CapturePreferences.quickAccessAutoCloseSeconds, 0)
        XCTAssertFalse(CapturePreferences.askForName)
        XCTAssertFalse(CapturePreferences.afterCaptureCopy)
        XCTAssertFalse(CapturePreferences.afterCaptureOpenEditor)
        XCTAssertFalse(CapturePreferences.afterCapturePin)
        XCTAssertFalse(CapturePreferences.afterCaptureUpload)
        XCTAssertFalse(CapturePreferences.afterCaptureSave)
        XCTAssertTrue(CapturePreferences.playShutterSound)
        XCTAssertFalse(CapturePreferences.convertToSRGB)
        XCTAssertTrue(CapturePreferences.urlSchemeEnabled)
        XCTAssertEqual(CapturePreferences.fileNameTemplate, "Parcel {date} at {time}")
        XCTAssertEqual(CapturePreferences.fileNameIndex, 0)
        XCTAssertFalse(CapturePreferences.ocrStripLineBreaks)
        XCTAssertFalse(CapturePreferences.scaleDownRetina)
        XCTAssertTrue(CapturePreferences.showCrosshair)
        XCTAssertTrue(CapturePreferences.showMagnifier)
        XCTAssertFalse(CapturePreferences.hideDesktopIcons)
        XCTAssertTrue(CapturePreferences.showAllInOneBar)

        CapturePreferences.useQuickAccess = false
        CapturePreferences.quickAccessAutoCloseSeconds = -5
        CapturePreferences.askForName = true
        CapturePreferences.afterCaptureCopy = true
        CapturePreferences.afterCaptureOpenEditor = true
        CapturePreferences.afterCapturePin = true
        CapturePreferences.afterCaptureUpload = true
        CapturePreferences.afterCaptureSave = true
        CapturePreferences.playShutterSound = false
        CapturePreferences.convertToSRGB = true
        CapturePreferences.urlSchemeEnabled = false
        CapturePreferences.fileNameTemplate = "Proof {index}"
        CapturePreferences.fileNameIndex = -3
        CapturePreferences.ocrStripLineBreaks = true
        CapturePreferences.scaleDownRetina = true
        CapturePreferences.showCrosshair = false
        CapturePreferences.showMagnifier = false
        CapturePreferences.hideDesktopIcons = true
        CapturePreferences.showAllInOneBar = false

        XCTAssertFalse(CapturePreferences.useQuickAccess)
        XCTAssertEqual(CapturePreferences.quickAccessAutoCloseSeconds, 0)
        XCTAssertTrue(CapturePreferences.askForName)
        XCTAssertTrue(CapturePreferences.afterCaptureCopy)
        XCTAssertTrue(CapturePreferences.afterCaptureOpenEditor)
        XCTAssertTrue(CapturePreferences.afterCapturePin)
        XCTAssertTrue(CapturePreferences.afterCaptureUpload)
        XCTAssertTrue(CapturePreferences.afterCaptureSave)
        XCTAssertFalse(CapturePreferences.playShutterSound)
        XCTAssertTrue(CapturePreferences.convertToSRGB)
        XCTAssertFalse(CapturePreferences.urlSchemeEnabled)
        XCTAssertEqual(CapturePreferences.fileNameTemplate, "Proof {index}")
        XCTAssertEqual(CapturePreferences.fileNameIndex, 0)
        XCTAssertTrue(CapturePreferences.ocrStripLineBreaks)
        XCTAssertTrue(CapturePreferences.scaleDownRetina)
        XCTAssertFalse(CapturePreferences.showCrosshair)
        XCTAssertFalse(CapturePreferences.showMagnifier)
        XCTAssertTrue(CapturePreferences.hideDesktopIcons)
        XCTAssertFalse(CapturePreferences.showAllInOneBar)
    }

    func testShutterSoundFeedbackHonorsPreferenceWithoutPlayingWhenDisabled() {
        var playedIDs: [SystemSoundID] = []

        XCTAssertFalse(ShutterSoundFeedback.playIfEnabled(false) { playedIDs.append($0) })
        XCTAssertTrue(playedIDs.isEmpty)

        XCTAssertTrue(ShutterSoundFeedback.playIfEnabled(true) { playedIDs.append($0) })
        XCTAssertEqual(playedIDs, [ShutterSoundFeedback.captureCompleteSoundID])
        XCTAssertEqual(ShutterSoundFeedback.captureCompleteSoundID, 1108)
    }

    func testQuickAccessShortcutMappingAndSwipeDiscardThreshold() {
        let command: NSEvent.ModifierFlags = [.command]

        XCTAssertEqual(
            QuickAccessShortcut.action(charactersIgnoringModifiers: "c", modifierFlags: command, keyCode: 8),
            .copy
        )
        XCTAssertEqual(
            QuickAccessShortcut.action(charactersIgnoringModifiers: "s", modifierFlags: command, keyCode: 1),
            .save
        )
        XCTAssertEqual(
            QuickAccessShortcut.action(charactersIgnoringModifiers: "w", modifierFlags: command, keyCode: 13),
            .close
        )
        XCTAssertEqual(
            QuickAccessShortcut.action(charactersIgnoringModifiers: "u", modifierFlags: command, keyCode: 32),
            .upload
        )
        XCTAssertEqual(
            QuickAccessShortcut.action(charactersIgnoringModifiers: "e", modifierFlags: command, keyCode: 14),
            .annotate
        )
        XCTAssertEqual(
            QuickAccessShortcut.action(charactersIgnoringModifiers: "p", modifierFlags: command, keyCode: 35),
            .printCapture
        )
        XCTAssertEqual(
            QuickAccessShortcut.action(charactersIgnoringModifiers: nil, modifierFlags: [], keyCode: 53),
            .close
        )
        XCTAssertNil(QuickAccessShortcut.action(charactersIgnoringModifiers: "c", modifierFlags: [], keyCode: 8))
        XCTAssertNil(QuickAccessShortcut.action(charactersIgnoringModifiers: "x", modifierFlags: command, keyCode: 7))

        XCTAssertFalse(QuickAccessSwipe.shouldDiscard(translationHeight: 80))
        XCTAssertTrue(QuickAccessSwipe.shouldDiscard(translationHeight: 80.1))
    }

    func testRecentlyClosedCapturesRestoreNewestFirstAndPruneOldEntries() throws {
        var stack = RecentlyClosedCaptures(limit: 3)
        XCTAssertNil(stack.restore())

        for width in [10, 20, 30, 40] {
            stack.push(Capture(image: try makeTestImage(width: width, height: 5), scale: 1))
        }

        XCTAssertEqual(stack.count, 3)
        XCTAssertEqual(stack.restore()?.image.width, 40)
        XCTAssertEqual(stack.restore()?.image.width, 30)
        XCTAssertEqual(stack.restore()?.image.width, 20)
        XCTAssertNil(stack.restore())
    }

    func testClipboardCaptureReaderImportsImageAndRejectsEmptyPasteboard() throws {
        let name = NSPasteboard.Name("dev.parable.ParcelTests.clipboard.\(UUID().uuidString)")
        let pasteboard = NSPasteboard(name: name)
        pasteboard.clearContents()
        XCTAssertNil(ClipboardCaptureReader.capture(from: pasteboard, scale: 2))

        let image = NSImage(cgImage: try makeTestImage(width: 12, height: 8), size: CGSize(width: 6, height: 4))
        XCTAssertTrue(pasteboard.writeObjects([image]))

        let capture = try XCTUnwrap(ClipboardCaptureReader.capture(from: pasteboard, scale: 2))
        XCTAssertEqual(capture.scale, 2)
        XCTAssertEqual(capture.image.width, 12)
        XCTAssertEqual(capture.image.height, 8)
        XCTAssertEqual(capture.pointSize.width, 6)
        XCTAssertEqual(capture.pointSize.height, 4)
        XCTAssertEqual(ClipboardCaptureReader.capture(from: pasteboard, scale: 0)?.scale, 1)

        pasteboard.clearContents()
    }

    func testCapturePrintPayloadPreservesImageSizeAndFitPagination() throws {
        let image = NSImage(cgImage: try makeTestImage(width: 18, height: 12), size: CGSize(width: 9, height: 6))
        let view = CapturePrintPayload.printableView(for: image)
        XCTAssertEqual(view.image, image)
        XCTAssertEqual(view.frame.origin, .zero)
        XCTAssertEqual(view.frame.size.width, 9)
        XCTAssertEqual(view.frame.size.height, 6)

        let base = NSPrintInfo()
        base.horizontalPagination = .clip
        base.verticalPagination = .clip
        let info = CapturePrintPayload.printInfo(from: base)
        XCTAssertEqual(info.horizontalPagination, .fit)
        XCTAssertEqual(info.verticalPagination, .fit)
        XCTAssertEqual(base.horizontalPagination, .clip)
        XCTAssertEqual(base.verticalPagination, .clip)
    }

    func testCaptureSharePayloadUsesRenderedImageAndContentAnchor() throws {
        let image = NSImage(cgImage: try makeTestImage(width: 22, height: 14), size: CGSize(width: 11, height: 7))
        let items = CaptureSharePayload.items(for: image)
        XCTAssertEqual(items.count, 1)
        XCTAssertTrue((items[0] as? NSImage) === image)

        XCTAssertNil(CaptureSharePayload.anchor(in: nil))

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 123, height: 45),
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        let content = NSView(frame: NSRect(x: 0, y: 0, width: 123, height: 45))
        window.contentView = content

        let anchor = try XCTUnwrap(CaptureSharePayload.anchor(in: window))
        XCTAssertTrue(anchor.view === content)
        XCTAssertEqual(anchor.rect, content.bounds)
        XCTAssertEqual(anchor.preferredEdge, .minY)
    }

    func testSnapWindowPickerChoosesSmallestContainingWindow() {
        let desktop = SnapWindow(
            id: 1,
            title: "Desktop",
            appName: "Finder",
            frameInScreen: CGRect(x: 0, y: 0, width: 600, height: 400)
        )
        let appWindow = SnapWindow(
            id: 2,
            title: "Document",
            appName: "Parcel",
            frameInScreen: CGRect(x: 100, y: 80, width: 300, height: 220)
        )
        let popover = SnapWindow(
            id: 3,
            title: "Popover",
            appName: "Parcel",
            frameInScreen: CGRect(x: 160, y: 120, width: 120, height: 90)
        )

        XCTAssertEqual(
            SnapWindowPicker.frontmostWindow(at: CGPoint(x: 170, y: 130), windows: [desktop, appWindow, popover]),
            popover
        )
        XCTAssertEqual(
            SnapWindowPicker.frontmostWindow(at: CGPoint(x: 120, y: 100), windows: [desktop, appWindow, popover]),
            appWindow
        )
        XCTAssertEqual(
            SnapWindowPicker.frontmostWindow(at: CGPoint(x: 20, y: 20), windows: [desktop, appWindow, popover]),
            desktop
        )
        XCTAssertNil(
            SnapWindowPicker.frontmostWindow(at: CGPoint(x: 700, y: 20), windows: [desktop, appWindow, popover])
        )
    }

    func testPinnedCaptureInteractionClampsOpacityAndMapsCloseGestures() {
        XCTAssertEqual(PinnedCaptureInteraction.clampedOpacity(1.4), 1)
        XCTAssertEqual(PinnedCaptureInteraction.clampedOpacity(0.1), 0.2)
        XCTAssertEqual(PinnedCaptureInteraction.adjustedOpacity(current: 1, delta: 0.05), 1)
        XCTAssertEqual(PinnedCaptureInteraction.adjustedOpacity(current: 0.21, delta: -0.05), 0.2)
        XCTAssertEqual(PinnedCaptureInteraction.adjustedOpacity(current: 0.5, delta: 0.05), 0.55)

        XCTAssertEqual(PinnedCaptureInteraction.opacityDelta(forScrollingDeltaY: 3), 0.05)
        XCTAssertEqual(PinnedCaptureInteraction.opacityDelta(forScrollingDeltaY: -3), -0.05)
        XCTAssertEqual(PinnedCaptureInteraction.opacityDelta(forScrollingDeltaY: 0), -0.05)

        XCTAssertTrue(PinnedCaptureInteraction.shouldClose(eventType: .otherMouseDown, buttonNumber: 0))
        XCTAssertTrue(PinnedCaptureInteraction.shouldClose(eventType: .leftMouseDown, buttonNumber: 2))
        XCTAssertFalse(PinnedCaptureInteraction.shouldClose(eventType: .leftMouseDown, buttonNumber: 0))
    }

    func testPinnedCaptureStateTracksLockVisibilityAndOpacity() {
        var state = PinnedCaptureState(opacity: 1.4)
        XCTAssertEqual(state.opacity, 1)
        XCTAssertFalse(state.locked)
        XCTAssertFalse(state.isHidden)
        XCTAssertFalse(state.ignoresMouseEvents)

        state.setHidden(true)
        XCTAssertTrue(state.isHidden)
        state.setHidden(false)
        XCTAssertFalse(state.isHidden)

        XCTAssertTrue(state.toggleLock())
        XCTAssertTrue(state.locked)
        XCTAssertTrue(state.ignoresMouseEvents)
        XCTAssertFalse(state.toggleLock())
        XCTAssertFalse(state.ignoresMouseEvents)

        XCTAssertEqual(state.setOpacity(0.05), 0.2)
        XCTAssertEqual(state.opacity, 0.2)
        XCTAssertEqual(state.adjustOpacity(by: 0.17), 0.37, accuracy: 0.0001)
        XCTAssertEqual(state.adjustOpacity(by: 2), 1)
    }

    func testScrollCaptureStitcherComposesVerticalAndHorizontalOverlaps() throws {
        let upper = try makePatternedImage(width: 96, height: 96, offsetX: 0, offsetY: 0)
        let lower = try makePatternedImage(width: 96, height: 96, offsetX: 0, offsetY: 48)

        let vertical = try XCTUnwrap(ScrollCaptureStitcher.append(upper: upper, lower: lower))
        XCTAssertEqual(vertical.width, 96)
        XCTAssertEqual(vertical.height, 144)

        let left = try makePatternedImage(width: 96, height: 96, offsetX: 0, offsetY: 0)
        let right = try makePatternedImage(width: 96, height: 96, offsetX: 48, offsetY: 0)

        let horizontal = try XCTUnwrap(ScrollCaptureStitcher.append(upper: left, lower: right))
        XCTAssertEqual(horizontal.width, 144)
        XCTAssertEqual(horizontal.height, 96)
    }

    func testScrollCaptureStitcherRejectsFramesWithoutReliableOverlap() throws {
        let black = try makeSolidImage(width: 96, height: 96, red: 0, green: 0, blue: 0)
        let white = try makeSolidImage(width: 96, height: 96, red: 255, green: 255, blue: 255)

        XCTAssertNil(try ScrollCaptureStitcher.append(upper: black, lower: white))
    }

    func testAllDisplayStitcherPreservesDesktopArrangementAndGaps() throws {
        let blue = try makeSolidImage(width: 2, height: 2, red: 0, green: 0, blue: 255)
        let red = try makeSolidImage(width: 2, height: 2, red: 255, green: 0, blue: 0)
        let green = try makeSolidImage(width: 2, height: 2, red: 0, green: 255, blue: 0)

        let capture = try XCTUnwrap(
            AllDisplayStitcher.stitch(
                [
                    AllDisplayStitcher.Item(frame: CGRect(x: -2, y: 0, width: 2, height: 2), image: blue, scale: 1),
                    AllDisplayStitcher.Item(frame: CGRect(x: 0, y: 0, width: 2, height: 2), image: red, scale: 1),
                    AllDisplayStitcher.Item(frame: CGRect(x: 0, y: 2, width: 2, height: 2), image: green, scale: 1),
                ],
                scaleDownRetina: false
            )
        )

        XCTAssertEqual(capture.scale, 1)
        XCTAssertEqual(capture.image.width, 4)
        XCTAssertEqual(capture.image.height, 4)
        XCTAssertEqual(try pixelRGBA(in: capture.image, x: 0, y: 0).r, 0)
        XCTAssertEqual(try pixelRGBA(in: capture.image, x: 0, y: 0).g, 0)
        XCTAssertEqual(try pixelRGBA(in: capture.image, x: 0, y: 0).b, 0)
        XCTAssertEqual(try pixelRGBA(in: capture.image, x: 2, y: 0).g, 255)
        XCTAssertEqual(try pixelRGBA(in: capture.image, x: 0, y: 2).b, 255)
        XCTAssertEqual(try pixelRGBA(in: capture.image, x: 2, y: 2).r, 255)
        XCTAssertNil(AllDisplayStitcher.stitch([], scaleDownRetina: false))
    }

    func testExtraHotKeyBindingsCoverClaimedCaptureAreaShortcutsAndOverrides() {
        let prefix = "\(AppIdentity.defaultsPrefix).hotkey"
        let keys = [
            "copy.keyCode", "copy.modifiers", "copy.enabled",
            "annotate.keyCode", "annotate.modifiers", "annotate.enabled",
            "pin.keyCode", "pin.modifiers", "pin.enabled",
            "save.keyCode", "save.modifiers", "save.enabled",
            "previous.keyCode", "previous.modifiers", "previous.enabled",
            "clipboard.keyCode", "clipboard.modifiers", "clipboard.enabled",
            "restore.keyCode", "restore.modifiers", "restore.enabled",
            "hide.keyCode", "hide.modifiers", "hide.enabled",
            "last.keyCode", "last.modifiers", "last.enabled",
            "ocr.keyCode", "ocr.modifiers", "ocr.enabled",
        ].map { "\(prefix).\($0)" }
        let defaults = UserDefaults.standard
        let previousValues: [(String, Any?)] = keys.map { ($0, defaults.object(forKey: $0)) }
        defer {
            for (key, value) in previousValues {
                if let value {
                    defaults.set(value, forKey: key)
                } else {
                    defaults.removeObject(forKey: key)
                }
            }
        }

        keys.forEach { defaults.removeObject(forKey: $0) }

        let defaultsByAction = Dictionary(uniqueKeysWithValues: HotKeyPreferences.extraBindings.map { ($0.action, $0) })
        XCTAssertEqual(defaultsByAction[.captureCopy]?.keyCode, UInt32(kVK_ANSI_C))
        XCTAssertEqual(defaultsByAction[.captureCopy]?.modifiers, UInt32(cmdKey | shiftKey | optionKey))
        XCTAssertEqual(defaultsByAction[.captureCopy]?.isEnabled, true)
        XCTAssertEqual(defaultsByAction[.captureAnnotate]?.keyCode, UInt32(kVK_ANSI_A))
        XCTAssertEqual(defaultsByAction[.captureAnnotate]?.isEnabled, true)
        XCTAssertEqual(defaultsByAction[.capturePin]?.keyCode, UInt32(kVK_ANSI_P))
        XCTAssertEqual(defaultsByAction[.capturePin]?.isEnabled, true)
        XCTAssertEqual(defaultsByAction[.captureSave]?.keyCode, UInt32(kVK_ANSI_S))
        XCTAssertEqual(defaultsByAction[.captureSave]?.isEnabled, false)
        XCTAssertEqual(defaultsByAction[.capturePrevious]?.keyCode, UInt32(kVK_ANSI_5))
        XCTAssertEqual(defaultsByAction[.capturePrevious]?.modifiers, UInt32(cmdKey | shiftKey))
        XCTAssertEqual(defaultsByAction[.capturePrevious]?.isEnabled, true)
        XCTAssertEqual(defaultsByAction[.openClipboard]?.keyCode, UInt32(kVK_ANSI_V))
        XCTAssertEqual(defaultsByAction[.openClipboard]?.isEnabled, false)
        XCTAssertEqual(defaultsByAction[.restoreClosed]?.keyCode, UInt32(kVK_ANSI_Z))
        XCTAssertEqual(defaultsByAction[.restoreClosed]?.isEnabled, true)
        XCTAssertEqual(defaultsByAction[.hideOverlays]?.keyCode, UInt32(kVK_ANSI_H))
        XCTAssertEqual(defaultsByAction[.hideOverlays]?.isEnabled, true)
        XCTAssertEqual(defaultsByAction[.annotateLast]?.keyCode, UInt32(kVK_ANSI_E))
        XCTAssertEqual(defaultsByAction[.annotateLast]?.isEnabled, false)
        XCTAssertEqual(defaultsByAction[.ocr]?.keyCode, UInt32(kVK_ANSI_T))
        XCTAssertEqual(defaultsByAction[.ocr]?.isEnabled, false)

        defaults.set(kVK_ANSI_B, forKey: "\(prefix).copy.keyCode")
        defaults.set(Int(cmdKey | controlKey), forKey: "\(prefix).copy.modifiers")
        defaults.set(false, forKey: "\(prefix).copy.enabled")
        defaults.set(true, forKey: "\(prefix).save.enabled")

        let customByAction = Dictionary(uniqueKeysWithValues: HotKeyPreferences.extraBindings.map { ($0.action, $0) })
        XCTAssertEqual(customByAction[.captureCopy]?.keyCode, UInt32(kVK_ANSI_B))
        XCTAssertEqual(customByAction[.captureCopy]?.modifiers, UInt32(cmdKey | controlKey))
        XCTAssertEqual(customByAction[.captureCopy]?.isEnabled, false)
        XCTAssertEqual(customByAction[.captureSave]?.isEnabled, true)
    }

    func testHotKeyAndRecordingPreferenceModelsMatchClaimedControls() {
        XCTAssertEqual(
            HotKeyDisplay.string(keyCode: UInt32(kVK_ANSI_2), modifiers: UInt32(cmdKey | shiftKey)),
            "⇧⌘2"
        )
        XCTAssertEqual(
            HotKeyDisplay.string(keyCode: UInt32(kVK_ANSI_5), modifiers: UInt32(cmdKey | shiftKey)),
            "⇧⌘5"
        )
        XCTAssertTrue(HotKeyPreferences.isReservedSystemShortcut(keyCode: UInt32(kVK_ANSI_W), modifiers: UInt32(cmdKey)))
        XCTAssertTrue(HotKeyPreferences.isReservedSystemShortcut(keyCode: UInt32(kVK_ANSI_Q), modifiers: UInt32(cmdKey)))
        XCTAssertFalse(
            HotKeyPreferences.isReservedSystemShortcut(
                keyCode: UInt32(kVK_ANSI_W),
                modifiers: UInt32(cmdKey | shiftKey)
            )
        )

        XCTAssertEqual(RecordingFPS.allCases.map(\.label), ["30 fps", "60 fps", "120 fps"])
        XCTAssertEqual(RecordingFPS.fps60.frameInterval.value, 1)
        XCTAssertEqual(RecordingFPS.fps60.frameInterval.timescale, 60)
        XCTAssertEqual(RecordingMaxResolution.allCases.map(\.label), ["Native", "1080p", "720p", "480p"])
        XCTAssertNil(RecordingMaxResolution.native.maxLongEdge)
        XCTAssertEqual(RecordingMaxResolution.p1080.maxLongEdge, 1920)
        XCTAssertEqual(RecordingMaxResolution.p720.maxLongEdge, 1280)
        XCTAssertEqual(RecordingMaxResolution.p480.maxLongEdge, 854)
        XCTAssertEqual(
            RecordingHUDPosition.allCases.map(\.label),
            ["Bottom center", "Bottom left", "Bottom right", "Top center"]
        )
    }

    func testKeystrokeHUDLabelsAndWebcamPiPPlacement() {
        XCTAssertEqual(
            KeystrokeHUDLabel.label(
                eventType: .flagsChanged,
                keyCode: 0,
                charactersIgnoringModifiers: nil,
                modifierFlags: [.shift, .command],
                commandOnly: true
            ),
            "⇧⌘"
        )
        XCTAssertNil(
            KeystrokeHUDLabel.label(
                eventType: .flagsChanged,
                keyCode: 0,
                charactersIgnoringModifiers: nil,
                modifierFlags: [],
                commandOnly: true
            )
        )
        XCTAssertEqual(
            KeystrokeHUDLabel.label(
                eventType: .keyDown,
                keyCode: UInt16(kVK_ANSI_A),
                charactersIgnoringModifiers: "a",
                modifierFlags: [.shift, .command],
                commandOnly: true
            ),
            "⇧⌘A"
        )
        XCTAssertEqual(
            KeystrokeHUDLabel.label(
                eventType: .keyDown,
                keyCode: UInt16(kVK_Return),
                charactersIgnoringModifiers: "\r",
                modifierFlags: [],
                commandOnly: false
            ),
            "↩"
        )
        XCTAssertEqual(
            KeystrokeHUDLabel.label(
                eventType: .keyDown,
                keyCode: UInt16(kVK_Space),
                charactersIgnoringModifiers: " ",
                modifierFlags: [.option],
                commandOnly: true
            ),
            "⌥Space"
        )
        XCTAssertNil(
            KeystrokeHUDLabel.label(
                eventType: .keyDown,
                keyCode: UInt16(kVK_ANSI_X),
                charactersIgnoringModifiers: "x",
                modifierFlags: [],
                commandOnly: true
            )
        )
        XCTAssertNil(
            KeystrokeHUDLabel.label(
                eventType: .keyDown,
                keyCode: UInt16(kVK_Shift),
                charactersIgnoringModifiers: nil,
                modifierFlags: [.shift],
                commandOnly: false
            )
        )

        XCTAssertEqual(WebcamPiPGeometry.diameter, 168)
        XCTAssertEqual(
            WebcamPiPGeometry.bottomRightOrigin(
                screen: CGRect(x: 100, y: 50, width: 1000, height: 700),
                windowSize: CGSize(width: 168, height: 168)
            ),
            CGPoint(x: 908, y: 74)
        )
    }

    func testCountdownDisplayAndFocusAssistPolicy() {
        XCTAssertEqual(CountdownDisplay.tickInterval, 0.1)
        XCTAssertEqual(CountdownDisplay.nextRemaining(after: 3), 2.9, accuracy: 0.0001)
        XCTAssertEqual(CountdownDisplay.nextRemaining(after: 0.05), 0, accuracy: 0.0001)

        XCTAssertEqual(CountdownDisplay.captureLabel(remaining: 3), "Capturing in 3s…")
        XCTAssertEqual(CountdownDisplay.captureLabel(remaining: 2.01), "Capturing in 3s…")
        XCTAssertEqual(CountdownDisplay.captureLabel(remaining: 2.0), "Capturing in 2s…")
        XCTAssertEqual(CountdownDisplay.recordingLabel(remaining: 0.01), "Recording in 1s…")
        XCTAssertEqual(CountdownDisplay.recordingLabel(remaining: -1), "Recording in 0s…")

        XCTAssertEqual(
            FocusAssist.script(for: true),
            "tell application \"System Events\" to keystroke \"d\" using {command down, option down}"
        )
        XCTAssertNil(FocusAssist.script(for: false))
    }

    func testRecordingGeometryAppliesEvenDimensionsAndMaxResolutionCaps() {
        XCTAssertEqual(
            RecordingGeometry.pixelSize(
                captureSizeInPoints: CGSize(width: 960, height: 540),
                scale: 2,
                maxResolution: .native
            ),
            RecordingPixelSize(width: 1920, height: 1080)
        )
        XCTAssertEqual(
            RecordingGeometry.pixelSize(
                captureSizeInPoints: CGSize(width: 3.4, height: 1.1),
                scale: 1,
                maxResolution: .native
            ),
            RecordingPixelSize(width: 2, height: 2)
        )
        XCTAssertEqual(
            RecordingGeometry.pixelSize(
                captureSizeInPoints: CGSize(width: 3000, height: 2000),
                scale: 1,
                maxResolution: .p1080
            ),
            RecordingPixelSize(width: 1920, height: 1280)
        )
        XCTAssertEqual(
            RecordingGeometry.pixelSize(
                captureSizeInPoints: CGSize(width: 1000, height: 3000),
                scale: 1,
                maxResolution: .p720
            ),
            RecordingPixelSize(width: 426, height: 1280)
        )
        XCTAssertEqual(
            RecordingGeometry.pixelSize(
                captureSizeInPoints: CGSize(width: 400, height: 300),
                scale: 1,
                maxResolution: .p480
            ),
            RecordingPixelSize(width: 400, height: 300)
        )
    }

    func testRecordingInstallUsesTemporaryWorkingFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ParcelRecordingInstall-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let destination = directory.appendingPathComponent("final.mp4")
        let working = ScreenRecorder.workingRecordingURL(for: destination)

        XCTAssertNotEqual(working, destination)
        XCTAssertEqual(working.pathExtension, "mp4")

        try Data("original".utf8).write(to: destination)
        try Data("finished".utf8).write(to: working)

        XCTAssertEqual(try Data(contentsOf: destination), Data("original".utf8))

        try ScreenRecorder.installFinishedRecording(from: working, to: destination)

        XCTAssertEqual(try Data(contentsOf: destination), Data("finished".utf8))
        XCTAssertFalse(FileManager.default.fileExists(atPath: working.path))
    }

    func testProductionRecordingWriterFinalizesMP4AndSkipsPausedSamples() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ParcelRecordingWriter-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = directory.appendingPathComponent("writer.mp4")
        let writer = try LegacyRecordingWriter(url: url, videoSize: CGSize(width: 64, height: 48), monoAudio: true)

        for frame in 0..<14 {
            writer.receiveSampleForTesting(
                try makeVideoSampleBuffer(width: 64, height: 48, frame: frame),
                type: .screen
            )
        }
        writer.flushSamplesForTesting()
        let countBeforePause = writer.videoSampleCountForTesting
        let receivedBeforePause = writer.receivedVideoSampleCountForTesting
        XCTAssertGreaterThan(countBeforePause, 0)

        writer.isPaused = true
        for frame in 14..<18 {
            writer.receiveSampleForTesting(
                try makeVideoSampleBuffer(width: 64, height: 48, frame: frame),
                type: .screen
            )
        }
        writer.flushSamplesForTesting()
        XCTAssertEqual(writer.videoSampleCountForTesting, countBeforePause)
        XCTAssertEqual(writer.receivedVideoSampleCountForTesting, receivedBeforePause)

        writer.isPaused = false
        for frame in 18..<22 {
            writer.receiveSampleForTesting(
                try makeVideoSampleBuffer(width: 64, height: 48, frame: frame),
                type: .screen
            )
        }
        writer.flushSamplesForTesting()
        XCTAssertGreaterThan(writer.receivedVideoSampleCountForTesting, receivedBeforePause)

        try await writer.finish()

        let data = try Data(contentsOf: url)
        XCTAssertNotNil(data.range(of: Data("moov".utf8)))

        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let videoTracks = try await asset.loadTracks(withMediaType: .video)

        XCTAssertGreaterThan(duration.seconds, 0)
        XCTAssertEqual(videoTracks.count, 1)
    }

    func testRecordingTrimModelExportsMP4AndGIF() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ParcelRecordingExport-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let sourceURL = directory.appendingPathComponent("source.mp4")
        try await makeTestRecordingMP4(at: sourceURL, frameCount: 36)

        let model = RecordingEditorModel(url: sourceURL, autoloadDuration: false)
        await model.loadDuration()
        XCTAssertGreaterThan(model.duration, 0.1)

        model.startTime = model.duration * 0.25
        model.endTime = model.duration * 0.75
        XCTAssertGreaterThanOrEqual(model.trimmedDuration, 0.1)

        let mp4URL = directory.appendingPathComponent("trimmed.mp4")
        let gifURL = directory.appendingPathComponent("trimmed.gif")
        try await model.writeMP4(to: mp4URL)
        try await model.writeGIF(to: gifURL)

        let mp4Asset = AVURLAsset(url: mp4URL)
        let mp4Duration = try await mp4Asset.load(.duration)
        let mp4VideoTracks = try await mp4Asset.loadTracks(withMediaType: .video)
        XCTAssertGreaterThan(mp4Duration.seconds, 0.1)
        XCTAssertEqual(mp4VideoTracks.count, 1)
        XCTAssertNotNil(try Data(contentsOf: mp4URL).range(of: Data("moov".utf8)))

        let gifData = try Data(contentsOf: gifURL)
        XCTAssertTrue(gifData.starts(with: Data("GIF".utf8)))
        guard let gifSource = CGImageSourceCreateWithData(gifData as CFData, nil) else {
            XCTFail("Expected exported GIF to be readable by ImageIO")
            return
        }
        XCTAssertEqual(CGImageSourceGetType(gifSource) as String?, UTType.gif.identifier)
        XCTAssertGreaterThan(CGImageSourceGetCount(gifSource), 0)
    }

    func testUploadPreferencesAndNotConfiguredErrorStayLocal() async {
        let previousURL = UploadPreferences.supabaseURL
        let previousAnonKey = UploadPreferences.anonKey
        let previousBucket = UploadPreferences.bucketName
        let previousPublicBase = UploadPreferences.publicBaseURL
        defer {
            UploadPreferences.supabaseURL = previousURL
            UploadPreferences.anonKey = previousAnonKey
            UploadPreferences.bucketName = previousBucket
            UploadPreferences.publicBaseURL = previousPublicBase
        }

        UploadPreferences.supabaseURL = "  "
        UploadPreferences.anonKey = ""
        UploadPreferences.bucketName = "captures"
        UploadPreferences.publicBaseURL = "  https://cdn.example.test/captures  "

        XCTAssertFalse(UploadPreferences.isConfigured)
        XCTAssertEqual(UploadPreferences.publicBaseURL, "https://cdn.example.test/captures")

        do {
            _ = try await UploadService.uploadPNG(data: Data([0x89, 0x50, 0x4E, 0x47]), fileName: "local.png")
            XCTFail("Upload should fail before any network work when Supabase is not configured.")
        } catch UploadError.notConfigured {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Expected UploadError.notConfigured, got \(error)")
        }

        UploadPreferences.supabaseURL = " https://project.supabase.co/ "
        UploadPreferences.anonKey = " anon-key "
        UploadPreferences.bucketName = " captures "

        XCTAssertTrue(UploadPreferences.isConfigured)
        XCTAssertEqual(UploadPreferences.supabaseURL, "https://project.supabase.co/")
        XCTAssertEqual(UploadPreferences.anonKey, "anon-key")
        XCTAssertEqual(UploadPreferences.bucketName, "captures")
    }

    func testUploadServiceBuildsSupabaseRequestAndReturnsPublicURL() async throws {
        let previousURL = UploadPreferences.supabaseURL
        let previousAnonKey = UploadPreferences.anonKey
        let previousBucket = UploadPreferences.bucketName
        let previousPublicBase = UploadPreferences.publicBaseURL
        defer {
            UploadPreferences.supabaseURL = previousURL
            UploadPreferences.anonKey = previousAnonKey
            UploadPreferences.bucketName = previousBucket
            UploadPreferences.publicBaseURL = previousPublicBase
        }

        UploadPreferences.supabaseURL = "https://project.supabase.co/"
        UploadPreferences.anonKey = "anon-key"
        UploadPreferences.bucketName = "parcel bucket"
        UploadPreferences.publicBaseURL = "https://cdn.example.test/captures/"

        final class RequestBox { var request: URLRequest? }
        let box = RequestBox()
        let payload = Data([0x89, 0x50, 0x4E, 0x47])
        let result = try await UploadService.uploadPNG(
            data: payload,
            fileName: "Capture 1.png",
            dataLoader: { request in
                box.request = request
                let response = HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 201,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (Data("{}".utf8), response)
            }
        )

        let request = try XCTUnwrap(box.request)
        XCTAssertEqual(
            request.url?.absoluteString,
            "https://project.supabase.co/storage/v1/object/parcel%20bucket/Capture%201.png"
        )
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer anon-key")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "image/png")
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-upsert"), "true")
        XCTAssertEqual(request.httpBody, payload)
        XCTAssertEqual(result.absoluteString, "https://cdn.example.test/captures/Capture%201.png")
    }

    func testUploadServiceSurfacesHTTPErrorBody() async throws {
        let previousURL = UploadPreferences.supabaseURL
        let previousAnonKey = UploadPreferences.anonKey
        let previousBucket = UploadPreferences.bucketName
        let previousPublicBase = UploadPreferences.publicBaseURL
        defer {
            UploadPreferences.supabaseURL = previousURL
            UploadPreferences.anonKey = previousAnonKey
            UploadPreferences.bucketName = previousBucket
            UploadPreferences.publicBaseURL = previousPublicBase
        }

        UploadPreferences.supabaseURL = "https://project.supabase.co"
        UploadPreferences.anonKey = "bad-key"
        UploadPreferences.bucketName = "captures"
        UploadPreferences.publicBaseURL = ""

        do {
            _ = try await UploadService.uploadPNG(
                data: Data([1, 2, 3]),
                fileName: "private.png",
                dataLoader: { request in
                    let response = HTTPURLResponse(
                        url: try XCTUnwrap(request.url),
                        statusCode: 401,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    return (Data("invalid token".utf8), response)
                }
            )
            XCTFail("Upload should surface Supabase HTTP errors.")
        } catch let UploadError.httpStatus(code, body) {
            XCTAssertEqual(code, 401)
            XCTAssertEqual(body, "invalid token")
        } catch {
            XCTFail("Expected UploadError.httpStatus, got \(error)")
        }
    }

    func testVisionAnalysisDetectsSensitiveTextLocally() {
        let observations = [
            VisionTextObservation(string: "hello team", rect: CGRect(x: 0, y: 0, width: 10, height: 10)),
            VisionTextObservation(string: "email jane@example.com", rect: CGRect(x: 0, y: 12, width: 10, height: 10)),
            VisionTextObservation(string: "+1 (555) 123-4567", rect: CGRect(x: 0, y: 24, width: 10, height: 10)),
            VisionTextObservation(string: "4242 4242 4242 4242", rect: CGRect(x: 0, y: 36, width: 10, height: 10)),
        ]
        let analysis = VisionAnalysis(text: observations)

        XCTAssertEqual(analysis.recognizedText, observations.map(\.string).joined(separator: "\n"))
        XCTAssertEqual(analysis.piiText.map(\.string), Array(observations.dropFirst()).map(\.string))
    }

    func testHighlighterSnapperSnapsNearbyPointsToTextBoxCenters() {
        let firstTextBox = CGRect(x: 20, y: 10, width: 40, height: 12)
        let secondTextBox = CGRect(x: 120, y: 50, width: 20, height: 30)
        let points = [
            CGPoint(x: 43, y: 18),
            CGPoint(x: 128, y: 70),
            CGPoint(x: 190, y: 160),
            CGPoint(x: 64, y: 16),
        ]

        let snapped = HighlighterSnapper.snappedPoints(points, to: [firstTextBox, secondTextBox])

        XCTAssertEqual(snapped[0], CGPoint(x: firstTextBox.midX, y: firstTextBox.midY))
        XCTAssertEqual(snapped[1], CGPoint(x: secondTextBox.midX, y: secondTextBox.midY))
        XCTAssertEqual(snapped[2], points[2])
        XCTAssertEqual(snapped[3], points[3], "The 24-point threshold is strict, so equal distance should not snap.")
        XCTAssertEqual(HighlighterSnapper.snappedPoints(points, to: []), points)
    }

    func testColorSwatchStorePersistsUniqueRecentColorsAndCapsAtTwelve() {
        let key = "\(AppIdentity.defaultsPrefix).editor.colorSwatches"
        let previous = UserDefaults.standard.data(forKey: key)
        defer {
            if let previous {
                UserDefaults.standard.set(previous, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        UserDefaults.standard.removeObject(forKey: key)

        let red = RGBAColor(red: 1, green: 0, blue: 0)
        ColorSwatchStore.add(red)
        ColorSwatchStore.add(red)
        XCTAssertEqual(ColorSwatchStore.load(), [red])

        let colors = (0..<13).map { index in
            RGBAColor(
                red: Double(index + 1) / 20,
                green: Double(index + 2) / 21,
                blue: Double(index + 3) / 22
            )
        }
        colors.forEach(ColorSwatchStore.add)

        XCTAssertEqual(ColorSwatchStore.load(), Array(colors.reversed().prefix(12)))
    }

    func testOCRTextFormatterHonorsLineBreakPreference() {
        let recognizedText = "  Parcel\n Capture  \n\nEditor\r\n Canvas  "

        XCTAssertEqual(
            OCRTextFormatter.outputText(from: recognizedText, stripLineBreaks: false),
            "Parcel\n Capture  \n\nEditor\r\n Canvas"
        )
        XCTAssertEqual(
            OCRTextFormatter.outputText(from: recognizedText, stripLineBreaks: true),
            "Parcel Capture Editor Canvas"
        )
        XCTAssertEqual(
            OCRTextFormatter.outputText(from: " \n\t ", stripLineBreaks: true),
            ""
        )
    }

    func testVisionAnalyzerDetectsQRCodeAndMapsCaptureRectsLocally() async throws {
        let payload = "parcel://capture/region?x=10&y=20&w=30&h=40"
        let image = try makeQRCodeImage(payload: payload, size: 256)
        let analysis = await VisionAnalyzer.analyze(image: image, pointSize: CGSize(width: 256, height: 256))

        XCTAssertTrue(
            analysis.qrCodes.contains { $0.payload == payload },
            "Expected local Vision analyzer to decode generated QR payload."
        )

        let mapped = VisionAnalyzer.captureRect(
            fromVision: CGRect(x: 0.25, y: 0.5, width: 0.5, height: 0.25),
            pointSize: CGSize(width: 200, height: 100)
        )
        XCTAssertEqual(mapped, CGRect(x: 50, y: 25, width: 100, height: 25))
    }

    func testWebPEncoderProducesRIFFWebPBytes() throws {
        let image = try makeTestImage(width: 32, height: 24)
        let data = try XCTUnwrap(ParcelWebPEncoder.encode(image))

        XCTAssertGreaterThan(data.count, 12)
        XCTAssertEqual(Array(data[0..<4]), Array("RIFF".utf8))
        XCTAssertEqual(Array(data[8..<12]), Array("WEBP".utf8))
    }

    func testSelectedOutputFormatsEncodeClaimedContainerTypes() throws {
        let image = try makeTestImage(width: 32, height: 24)
        let outputSize = CGSize(width: 32, height: 24)

        for format in OutputFormat.allCases {
            let data = try XCTUnwrap(
                EditorModel.encodeImage(image, as: format, outputSize: outputSize),
                "Expected \(format.label) encoder to produce data"
            )
            XCTAssertGreaterThan(data.count, 12, "Expected non-empty \(format.label) output")

            switch format {
            case .png:
                XCTAssertEqual(Array(data.prefix(4)), [0x89, 0x50, 0x4E, 0x47])
                XCTAssertEqual(imageSourceType(for: data), UTType.png.identifier)
            case .jpeg:
                XCTAssertEqual(Array(data.prefix(2)), [0xFF, 0xD8])
                XCTAssertEqual(imageSourceType(for: data), UTType.jpeg.identifier)
            case .heic:
                let sourceType = try XCTUnwrap(imageSourceType(for: data))
                XCTAssertTrue(
                    [UTType.heic.identifier, "public.heif"].contains(sourceType),
                    "Expected HEIC/HEIF data, got \(sourceType)"
                )
            case .tiff:
                let littleEndianTIFF = Array(data.prefix(4)) == [0x49, 0x49, 0x2A, 0x00]
                let bigEndianTIFF = Array(data.prefix(4)) == [0x4D, 0x4D, 0x00, 0x2A]
                XCTAssertTrue(littleEndianTIFF || bigEndianTIFF)
                XCTAssertEqual(imageSourceType(for: data), UTType.tiff.identifier)
            case .webp:
                XCTAssertEqual(Array(data.prefix(4)), Array("RIFF".utf8))
                XCTAssertEqual(Array(data.dropFirst(8).prefix(4)), Array("WEBP".utf8))
            }
        }
    }

    func testImageColorSpaceConversionProducesSRGBImageForExportPreference() throws {
        let p3 = CGColorSpace(name: CGColorSpace.displayP3) ?? CGColorSpaceCreateDeviceRGB()
        let image = try makeImage(width: 16, height: 12, colorSpace: p3) { x, y in
            (
                UInt8((x * 255) / 15),
                UInt8((y * 255) / 11),
                120,
                255
            )
        }

        let converted = try XCTUnwrap(ImageColorSpace.convertToSRGB(image))

        XCTAssertEqual(converted.width, image.width)
        XCTAssertEqual(converted.height, image.height)
        XCTAssertEqual(converted.colorSpace?.name as String?, CGColorSpace.sRGB as String)
    }

    func testParcelProjectRoundTripRestoresEditableState() throws {
        let fileManager = FileManager.default
        let url = fileManager.temporaryDirectory
            .appendingPathComponent("ParcelProject-\(UUID().uuidString)", isDirectory: true)
            .appendingPathExtension("parcel")
        defer { try? fileManager.removeItem(at: url) }

        let capture = Capture(image: try makeTestImage(width: 80, height: 60), scale: 2)
        let model = EditorModel(capture: capture)
        model.outputFormat = .webp
        model.adjustments = Adjustments(contrast: 1.08, saturation: 1.15, sharpness: 0.25)
        model.beautifyEnabled = true
        model.beautify.padding = 24
        model.beautify.cornerRadius = 8
        model.add(
            Annotation(
                kind: .rectangle(rect: CGRect(x: 8, y: 10, width: 24, height: 18)),
                style: AnnotationStyle(color: .blue, lineWidth: 3, fontSize: 18)
            )
        )

        ParcelProjectIO.save(model: model, to: url)

        XCTAssertTrue(fileManager.fileExists(atPath: url.appendingPathComponent("capture.png").path))
        XCTAssertTrue(fileManager.fileExists(atPath: url.appendingPathComponent("document.json").path))

        let restored = try XCTUnwrap(ParcelProjectIO.open(from: url))
        XCTAssertEqual(restored.capture.image.width, capture.image.width)
        XCTAssertEqual(restored.capture.image.height, capture.image.height)
        XCTAssertEqual(restored.capture.scale, capture.scale)
        XCTAssertEqual(restored.document.annotations, model.annotations)
        XCTAssertEqual(restored.document.adjustments, model.adjustments)
        XCTAssertEqual(restored.document.beautifyEnabled, model.beautifyEnabled)
        XCTAssertEqual(restored.document.beautify.padding, model.beautify.padding)
        XCTAssertEqual(restored.document.beautify.cornerRadius, model.beautify.cornerRadius)
        XCTAssertEqual(restored.document.outputFormat, .webp)
    }

    func testHistoryStoreCreateRestoreSaveAndDelete() throws {
        let fileManager = FileManager.default
        let rootURL = fileManager.temporaryDirectory
            .appendingPathComponent("ParcelHistory-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: rootURL) }

        let store = HistoryStore(fileManager: fileManager, rootURL: rootURL)
        let capture = Capture(image: try makeTestImage(width: 48, height: 32), scale: 2)
        let id = try XCTUnwrap(store.createDocument(for: capture))

        XCTAssertEqual(store.entries.map(\.id), [id])
        XCTAssertNotNil(store.preview(for: try XCTUnwrap(store.entry(for: id))))

        let restored = try XCTUnwrap(store.restore(id))
        XCTAssertEqual(restored.capture.image.width, capture.image.width)
        XCTAssertEqual(restored.capture.image.height, capture.image.height)
        XCTAssertEqual(restored.capture.scale, capture.scale)
        XCTAssertEqual(restored.document.annotations, [])
        XCTAssertEqual(restored.document.outputFormat, .png)

        var document = restored.document
        document.annotations = [
            Annotation(
                kind: .text(rect: CGRect(x: 4, y: 5, width: 30, height: 12), string: "History"),
                style: AnnotationStyle(color: .blue, lineWidth: 2, fontSize: 18)
            ),
        ]
        document.adjustments = Adjustments(brightness: 0.1, contrast: 1.1)
        document.beautifyEnabled = true
        document.beautify.padding = 18
        document.outputFormat = .webp
        store.save(document)

        let saved = try XCTUnwrap(store.restore(id))
        XCTAssertEqual(saved.document.annotations, document.annotations)
        XCTAssertEqual(saved.document.adjustments, document.adjustments)
        XCTAssertTrue(saved.document.beautifyEnabled)
        XCTAssertEqual(saved.document.beautify.padding, 18)
        XCTAssertEqual(saved.document.outputFormat, .webp)

        store.remove(id)
        XCTAssertTrue(store.entries.isEmpty)
        XCTAssertFalse(fileManager.fileExists(atPath: rootURL.appendingPathComponent(id.uuidString).path))
    }

    func testHistoryFilterAndRetentionPruneUsePersistedIndex() throws {
        let previousRetention = HistoryRetention.current
        defer { HistoryRetention.current = previousRetention }

        let fileManager = FileManager.default
        let rootURL = fileManager.temporaryDirectory
            .appendingPathComponent("ParcelHistoryRetention-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: rootURL) }
        try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)

        let now = Date()
        let freshID = UUID()
        let expiredID = UUID()
        let fresh = HistoryEntry(
            id: freshID,
            createdAt: now.addingTimeInterval(-60 * 60),
            updatedAt: now.addingTimeInterval(-60 * 60),
            captureFileName: "fresh-capture.png",
            pixelWidth: 640,
            pixelHeight: 480
        )
        let expired = HistoryEntry(
            id: expiredID,
            createdAt: now.addingTimeInterval(-8 * 24 * 60 * 60),
            updatedAt: now.addingTimeInterval(-8 * 24 * 60 * 60),
            captureFileName: "expired-capture.png",
            pixelWidth: 320,
            pixelHeight: 240
        )

        try fileManager.createDirectory(
            at: rootURL.appendingPathComponent(freshID.uuidString, isDirectory: true),
            withIntermediateDirectories: true
        )
        try fileManager.createDirectory(
            at: rootURL.appendingPathComponent(expiredID.uuidString, isDirectory: true),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode([expired, fresh]).write(to: rootURL.appendingPathComponent("index.json"), options: .atomic)

        XCTAssertTrue(fresh.matchesFilter("fresh"))
        XCTAssertTrue(fresh.matchesFilter("640x480"))
        XCTAssertTrue(fresh.matchesFilter("640 × 480"))
        XCTAssertTrue(fresh.matchesFilter("  "))
        XCTAssertFalse(fresh.matchesFilter("expired"))

        HistoryRetention.current = .week
        let store = HistoryStore(fileManager: fileManager, rootURL: rootURL)

        XCTAssertEqual(store.entries.map(\.id), [freshID])
        XCTAssertTrue(fileManager.fileExists(atPath: rootURL.appendingPathComponent(freshID.uuidString).path))
        XCTAssertFalse(fileManager.fileExists(atPath: rootURL.appendingPathComponent(expiredID.uuidString).path))

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let persistedEntries = try decoder.decode(
            [HistoryEntry].self,
            from: Data(contentsOf: rootURL.appendingPathComponent("index.json"))
        )
        XCTAssertEqual(persistedEntries.map(\.id), [freshID])
    }

    func testBrandKitStoreSavesReloadsAndRemovesBeautifySettingsLocally() {
        let suiteName = "ParcelBrandKitTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var settings = BeautifySettings()
        settings.background = .solid(RGBAColor(hex: 0x112233))
        settings.padding = 72
        settings.cornerRadius = 18
        settings.shadow.opacity = 0.42
        settings.chrome.enabled = true
        settings.chrome.title = "Launch"
        settings.chrome.style = .dark

        let store = BrandKitStore(userDefaults: defaults, defaultsKey: "brandKits")
        store.save(name: "  Launch Kit  ", settings: settings)
        store.save(name: "   ", settings: BeautifySettings())

        XCTAssertEqual(store.kits.count, 1)
        XCTAssertEqual(store.kits[0].name, "Launch Kit")
        XCTAssertEqual(store.kits[0].settings, settings)

        let reloaded = BrandKitStore(userDefaults: defaults, defaultsKey: "brandKits")
        XCTAssertEqual(reloaded.kits, store.kits)

        reloaded.remove(store.kits[0].id)
        XCTAssertTrue(reloaded.kits.isEmpty)
        XCTAssertTrue(BrandKitStore(userDefaults: defaults, defaultsKey: "brandKits").kits.isEmpty)
    }

    func testAnnotationUndoRedoAndLayerOrder() throws {
        let model = EditorModel(capture: Capture(image: try makeTestImage(width: 80, height: 60), scale: 1))
        let back = Annotation(
            kind: .rectangle(rect: CGRect(x: 5, y: 5, width: 20, height: 16)),
            style: AnnotationStyle(color: .red, lineWidth: 2, fontSize: 18)
        )
        let middle = Annotation(
            kind: .ellipse(rect: CGRect(x: 14, y: 14, width: 18, height: 18)),
            style: AnnotationStyle(color: .blue, lineWidth: 2, fontSize: 18)
        )
        let front = Annotation(
            kind: .arrow(start: CGPoint(x: 2, y: 40), end: CGPoint(x: 48, y: 8)),
            style: AnnotationStyle(color: .yellow, lineWidth: 3, fontSize: 18)
        )

        model.add(back)
        model.add(middle)
        model.add(front)

        XCTAssertEqual(model.annotations.map(\.id), [back.id, middle.id, front.id])
        XCTAssertTrue(model.canUndo)
        XCTAssertFalse(model.canRedo)

        model.selectedID = back.id
        model.bringToFront()
        XCTAssertEqual(model.annotations.map(\.id), [middle.id, front.id, back.id])

        model.undo()
        XCTAssertEqual(model.annotations.map(\.id), [back.id, middle.id, front.id])
        XCTAssertTrue(model.canRedo)

        model.redo()
        XCTAssertEqual(model.annotations.map(\.id), [middle.id, front.id, back.id])
    }

    func testDocumentSettingsStayOutOfAnnotationUndoStack() throws {
        let model = EditorModel(capture: Capture(image: try makeTestImage(width: 80, height: 60), scale: 1))
        model.add(
            Annotation(
                kind: .rectangle(rect: CGRect(x: 8, y: 8, width: 24, height: 18)),
                style: AnnotationStyle(color: .red, lineWidth: 2, fontSize: 18)
            )
        )

        model.adjustments = Adjustments(brightness: 0.5, contrast: 1.2, saturation: 0.9)
        model.beautifyEnabled = true
        model.beautify.padding = 32
        model.outputFormat = .webp

        model.undo()

        XCTAssertTrue(model.annotations.isEmpty)
        XCTAssertEqual(model.adjustments, Adjustments(brightness: 0.5, contrast: 1.2, saturation: 0.9))
        XCTAssertTrue(model.beautifyEnabled)
        XCTAssertEqual(model.beautify.padding, 32)
        XCTAssertEqual(model.outputFormat, .webp)
    }

    func testCropTransformRemapsAnnotationsInCapturePointSpace() throws {
        let model = EditorModel(capture: Capture(image: try makeTestImage(width: 200, height: 100), scale: 2))
        let rect = Annotation(
            kind: .rectangle(rect: CGRect(x: 10, y: 12, width: 20, height: 8)),
            style: AnnotationStyle(color: .red, lineWidth: 2, fontSize: 18)
        )
        let arrow = Annotation(
            kind: .arrow(start: CGPoint(x: 15, y: 20), end: CGPoint(x: 55, y: 40)),
            style: AnnotationStyle(color: .blue, lineWidth: 3, fontSize: 18)
        )

        model.add(rect)
        model.add(arrow)
        model.cropCapture(toPoints: CGRect(x: 5, y: 10, width: 80, height: 30))

        XCTAssertEqual(model.capture.pointSize.width, 80, accuracy: 0.001)
        XCTAssertEqual(model.capture.pointSize.height, 30, accuracy: 0.001)
        XCTAssertEqual(model.annotations.count, 2)
        XCTAssertEqual(model.annotations[0].kind, .rectangle(rect: CGRect(x: 5, y: 2, width: 20, height: 8)))
        XCTAssertEqual(model.annotations[1].kind, .arrow(start: CGPoint(x: 10, y: 10), end: CGPoint(x: 50, y: 30)))
    }

    func testTransformRemappingForRotateFlipAndScale() {
        let style = AnnotationStyle(color: .red, lineWidth: 2, fontSize: 18)
        let annotations = [
            Annotation(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                kind: .rectangle(rect: CGRect(x: 10, y: 20, width: 30, height: 10)),
                style: style
            ),
            Annotation(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                kind: .arrow(start: CGPoint(x: 5, y: 8), end: CGPoint(x: 60, y: 40)),
                style: style
            ),
            Annotation(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                kind: .number(center: CGPoint(x: 50, y: 25), radius: 6, value: 1),
                style: style
            ),
        ]

        let rotated = CaptureTransform.rotateAnnotations90CW(annotations, canvasSize: CGSize(width: 100, height: 50))
        XCTAssertEqual(rotated[0].kind, .rectangle(rect: CGRect(x: 20, y: 10, width: 10, height: 30)))
        XCTAssertEqual(rotated[0].rotation, .pi / 2, accuracy: 0.001)
        XCTAssertEqual(rotated[1].kind, .arrow(start: CGPoint(x: 42, y: 5), end: CGPoint(x: 10, y: 60)))
        XCTAssertEqual(rotated[2].kind, .number(center: CGPoint(x: 25, y: 50), radius: 6, value: 1))

        let flippedH = CaptureTransform.flipAnnotationsH(annotations, canvasWidth: 100)
        XCTAssertEqual(flippedH[0].kind, .rectangle(rect: CGRect(x: 60, y: 20, width: 30, height: 10)))
        XCTAssertEqual(flippedH[1].kind, .arrow(start: CGPoint(x: 95, y: 8), end: CGPoint(x: 40, y: 40)))

        let flippedV = CaptureTransform.flipAnnotationsV(annotations, canvasHeight: 50)
        XCTAssertEqual(flippedV[0].kind, .rectangle(rect: CGRect(x: 10, y: 20, width: 30, height: 10)))
        XCTAssertEqual(flippedV[1].kind, .arrow(start: CGPoint(x: 5, y: 42), end: CGPoint(x: 60, y: 10)))

        let scaled = CaptureTransform.scaleAnnotations(
            annotations,
            from: CGSize(width: 100, height: 50),
            to: CGSize(width: 200, height: 100)
        )
        XCTAssertEqual(scaled[0].kind, .rectangle(rect: CGRect(x: 20, y: 40, width: 60, height: 20)))
        XCTAssertEqual(scaled[1].kind, .arrow(start: CGPoint(x: 10, y: 16), end: CGPoint(x: 120, y: 80)))
        XCTAssertEqual(scaled[2].kind, .number(center: CGPoint(x: 100, y: 50), radius: 12, value: 1))
    }

    func testExpandAndCombineTransformsPreserveCapturePointPlacement() throws {
        let red = try makeSolidImage(width: 2, height: 2, red: 255, green: 0, blue: 0)
        let blue = NSColor(calibratedRed: 0, green: 0, blue: 1, alpha: 1)
        let capture = Capture(image: red, scale: 1)

        let expanded = try XCTUnwrap(
            CaptureTransform.expand(capture, top: 1, left: 2, bottom: 1, right: 1, fill: blue)
        )
        XCTAssertEqual(expanded.pointSize, CGSize(width: 5, height: 4))
        XCTAssertEqual(try pixelRGBA(in: expanded.image, x: 0, y: 0).b, 255)
        XCTAssertEqual(try pixelRGBA(in: expanded.image, x: 2, y: 1).r, 255)

        let model = EditorModel(capture: capture)
        let annotation = Annotation(
            kind: .rectangle(rect: CGRect(x: 0.25, y: 0.5, width: 1, height: 1)),
            style: AnnotationStyle(color: .red, lineWidth: 2, fontSize: 18)
        )
        model.add(annotation)
        model.expandCanvas(top: 1, left: 2, bottom: 1, right: 1, fill: blue)
        XCTAssertEqual(
            model.annotations.first?.kind,
            .rectangle(rect: CGRect(x: 2.25, y: 1.5, width: 1, height: 1))
        )

        let base = Capture(image: try makeSolidImage(width: 5, height: 5, red: 0, green: 0, blue: 255), scale: 1)
        let other = Capture(image: red, scale: 1)
        let combined = try XCTUnwrap(CaptureTransform.combine(base: base, other: other, into: CGRect(x: 1, y: 2, width: 2, height: 2)))
        XCTAssertEqual(try pixelRGBA(in: combined.image, x: 0, y: 0).b, 255)
        XCTAssertEqual(try pixelRGBA(in: combined.image, x: 1, y: 2).r, 255)
    }

    func testCensorEraseSamplesOutsideRingAndRetinaPointCoordinates() throws {
        let image = try makeImage(width: 8, height: 8) { x, y in
            if (2..<6).contains(x), (2..<6).contains(y) {
                return (255, 0, 0, 255)
            }
            return (0, 220, 0, 255)
        }

        let sampled = try XCTUnwrap(
            CensorEraseSampler.averageSurroundingColor(
                in: CGRect(x: 1, y: 1, width: 2, height: 2),
                image: image,
                pointSize: CGSize(width: 4, height: 4)
            )
        )
        XCTAssertLessThan(sampled.red, 0.05)
        XCTAssertGreaterThan(sampled.green, 0.80)
        XCTAssertLessThan(sampled.blue, 0.05)

        let fullImageSample = CensorEraseSampler.averageSurroundingColor(
            in: CGRect(x: 0, y: 0, width: 4, height: 4),
            image: image,
            pointSize: CGSize(width: 4, height: 4)
        )
        XCTAssertNil(fullImageSample)
    }

    func testRemoveBackgroundMakesWindowMatteTransparentAndPreservesForeground() throws {
        let image = try makeImage(width: 20, height: 20) { x, y in
            if (6..<14).contains(x), (6..<14).contains(y) {
                return (220, 20, 40, 255)
            }
            return (145, 145, 145, 255)
        }
        let capture = Capture(image: image, scale: 1)

        let cleaned = try XCTUnwrap(CaptureTransform.removeBackground(capture, tolerance: 4))
        let corner = try pixelRGBA(in: cleaned.image, x: 0, y: 0)
        let edge = try pixelRGBA(in: cleaned.image, x: 19, y: 19)
        let foreground = try pixelRGBA(in: cleaned.image, x: 10, y: 10)

        XCTAssertEqual(corner.a, 0)
        XCTAssertEqual(edge.a, 0)
        XCTAssertEqual(foreground.a, 255)
        XCTAssertGreaterThan(foreground.r, foreground.g)
    }

    func testCaptureFileNameTemplateSanitizesTokensAndIncrementsIndex() {
        let previousTemplate = CapturePreferences.fileNameTemplate
        let previousIndex = CapturePreferences.fileNameIndex
        defer {
            CapturePreferences.fileNameTemplate = previousTemplate
            CapturePreferences.fileNameIndex = previousIndex
        }

        CapturePreferences.fileNameTemplate = "{app}-{window}-{date}-{time}-{month}-{index}"
        CapturePreferences.fileNameIndex = 7

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let date = calendar.date(
            from: DateComponents(
                timeZone: .current,
                year: 2026,
                month: 8,
                day: 11,
                hour: 9,
                minute: 7,
                second: 6
            )
        )!

        let name = CaptureFileName.make(
            extension: "png",
            appName: " Preview/App ",
            windowTitle: "A:B?C",
            date: date
        )

        XCTAssertEqual(name, "Preview-App-A-B-C-2026-08-11-09.07.06-2026-08-7.png")
        XCTAssertEqual(CapturePreferences.fileNameIndex, 8)
    }

    func testPreviousAreaPreferencesRememberCaptureAndRecordingSelections() throws {
        let previousSelectionDisplayID = CapturePreferences.lastSelectionDisplayID
        let previousSelectionX = CapturePreferences.lastSelectionX
        let previousSelectionY = CapturePreferences.lastSelectionY
        let previousSelectionWidth = CapturePreferences.lastSelectionWidth
        let previousSelectionHeight = CapturePreferences.lastSelectionHeight
        let previousRecordingDisplayID = CapturePreferences.lastRecordingDisplayID
        let previousRecordingX = CapturePreferences.lastRecordingX
        let previousRecordingY = CapturePreferences.lastRecordingY
        let previousRecordingWidth = CapturePreferences.lastRecordingWidth
        let previousRecordingHeight = CapturePreferences.lastRecordingHeight
        defer {
            CapturePreferences.lastSelectionDisplayID = previousSelectionDisplayID
            CapturePreferences.lastSelectionX = previousSelectionX
            CapturePreferences.lastSelectionY = previousSelectionY
            CapturePreferences.lastSelectionWidth = previousSelectionWidth
            CapturePreferences.lastSelectionHeight = previousSelectionHeight
            CapturePreferences.lastRecordingDisplayID = previousRecordingDisplayID
            CapturePreferences.lastRecordingX = previousRecordingX
            CapturePreferences.lastRecordingY = previousRecordingY
            CapturePreferences.lastRecordingWidth = previousRecordingWidth
            CapturePreferences.lastRecordingHeight = previousRecordingHeight
        }

        CapturePreferences.lastSelectionDisplayID = 0
        CapturePreferences.lastSelectionWidth = 240
        CapturePreferences.lastSelectionHeight = 120
        XCTAssertFalse(CapturePreferences.hasPreviousArea)

        CapturePreferences.lastSelectionDisplayID = 91
        CapturePreferences.lastSelectionWidth = 1
        CapturePreferences.lastSelectionHeight = 120
        XCTAssertFalse(CapturePreferences.hasPreviousArea)

        let selectionRect = CGRect(x: 12.5, y: 24.25, width: 320.5, height: 180.75)
        let frozen = FrozenScreen(
            id: 91,
            screen: try XCTUnwrap(NSScreen.main),
            image: try makeTestImage(width: 8, height: 8),
            scale: 1,
            pointSize: CGSize(width: 8, height: 8),
            windows: []
        )
        CapturePreferences.rememberSelection(SelectionResult(screen: frozen, rectInPoints: selectionRect))
        XCTAssertTrue(CapturePreferences.hasPreviousArea)
        XCTAssertEqual(CapturePreferences.lastSelectionDisplayID, 91)
        XCTAssertEqual(CapturePreferences.lastSelectionRect, selectionRect)

        CapturePreferences.lastRecordingDisplayID = 0
        CapturePreferences.lastRecordingWidth = 200
        CapturePreferences.lastRecordingHeight = 100
        XCTAssertFalse(CapturePreferences.hasPreviousRecordingArea)

        CapturePreferences.lastRecordingDisplayID = 92
        CapturePreferences.lastRecordingWidth = 200
        CapturePreferences.lastRecordingHeight = 1
        XCTAssertFalse(CapturePreferences.hasPreviousRecordingArea)

        let recordingRect = CGRect(x: 44, y: 55, width: 640, height: 360)
        CapturePreferences.rememberRecordingSelection(displayID: 92, rect: recordingRect)
        XCTAssertTrue(CapturePreferences.hasPreviousRecordingArea)
        XCTAssertEqual(CapturePreferences.lastRecordingDisplayID, 92)
        XCTAssertEqual(CapturePreferences.lastRecordingX, recordingRect.origin.x)
        XCTAssertEqual(CapturePreferences.lastRecordingY, recordingRect.origin.y)
        XCTAssertEqual(CapturePreferences.lastRecordingWidth, recordingRect.width)
        XCTAssertEqual(CapturePreferences.lastRecordingHeight, recordingRect.height)
    }

    func testRetinaScaleDownPreferenceResizesCaptureToPointDimensions() throws {
        let previousScaleDown = CapturePreferences.scaleDownRetina
        defer { CapturePreferences.scaleDownRetina = previousScaleDown }

        let source = Capture(image: try makeTestImage(width: 20, height: 10), scale: 2)
        let engine = CaptureEngine()

        CapturePreferences.scaleDownRetina = false
        let original = engine.applyRetinaPreference(source)
        XCTAssertEqual(original.scale, 2)
        XCTAssertEqual(original.image.width, 20)
        XCTAssertEqual(original.image.height, 10)
        XCTAssertEqual(original.pointSize, CGSize(width: 10, height: 5))

        CapturePreferences.scaleDownRetina = true
        let scaled = engine.applyRetinaPreference(source)
        XCTAssertEqual(scaled.scale, 1)
        XCTAssertEqual(scaled.image.width, 10)
        XCTAssertEqual(scaled.image.height, 5)
        XCTAssertEqual(scaled.pointSize, CGSize(width: 10, height: 5))

        let oneBy = engine.applyRetinaPreference(Capture(image: try makeTestImage(width: 7, height: 6), scale: 1))
        XCTAssertEqual(oneBy.scale, 1)
        XCTAssertEqual(oneBy.image.width, 7)
        XCTAssertEqual(oneBy.image.height, 6)
    }

    func testSelectionAspectPresetGeometryHonorsRatiosAndShiftBypass() {
        XCTAssertEqual(SelectionAspectPreset.allCases.map(\.label), ["Free", "1:1", "4:3", "16:9"])
        XCTAssertEqual(SelectionAspectPreset.free.next, .square)
        XCTAssertEqual(SelectionAspectPreset.square.next, .standard)
        XCTAssertEqual(SelectionAspectPreset.standard.next, .widescreen)
        XCTAssertEqual(SelectionAspectPreset.widescreen.next, .free)

        let start = CGPoint(x: 100, y: 100)
        let draggedUpLeft = CGPoint(x: 60, y: 80)
        XCTAssertEqual(
            SelectionGeometry.rect(
                start: start,
                snappedEnd: draggedUpLeft,
                aspectPreset: .standard,
                bypassPreset: false
            ),
            CGRect(x: 60, y: 70, width: 40, height: 30)
        )
        XCTAssertEqual(
            SelectionGeometry.rect(
                start: start,
                snappedEnd: draggedUpLeft,
                aspectPreset: .standard,
                bypassPreset: true
            ),
            CGRect(x: 60, y: 80, width: 40, height: 20)
        )

        XCTAssertEqual(
            SelectionGeometry.rect(
                start: CGPoint(x: 10, y: 10),
                snappedEnd: CGPoint(x: 35, y: 60),
                aspectPreset: .square,
                bypassPreset: false
            ),
            CGRect(x: 10, y: 10, width: 50, height: 50)
        )
        XCTAssertEqual(
            SelectionGeometry.rect(
                start: CGPoint(x: 10, y: 10),
                snappedEnd: CGPoint(x: 30, y: 25),
                aspectPreset: .free,
                bypassPreset: false
            ),
            CGRect(x: 10, y: 10, width: 20, height: 15)
        )
    }

    private func makeTestImage(width: Int, height: Int) throws -> CGImage {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let bytesPerRow = width * 4
        var bytes = [UInt8](repeating: 0, count: bytesPerRow * height)

        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                bytes[offset] = UInt8((x * 255) / max(width - 1, 1))
                bytes[offset + 1] = UInt8((y * 255) / max(height - 1, 1))
                bytes[offset + 2] = 180
                bytes[offset + 3] = 255
            }
        }

        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              )
        else {
            throw XCTSkip("Could not create test CGImage")
        }
        return image
    }

    private func makePatternedImage(width: Int, height: Int, offsetX: Int, offsetY: Int) throws -> CGImage {
        try makeImage(width: width, height: height) { x, y in
            let globalX = UInt64(x + offsetX)
            let globalY = UInt64(y + offsetY)
            let seed = (globalX &* 73_856_093) ^ (globalY &* 19_349_663)
            return (
                UInt8(truncatingIfNeeded: seed),
                UInt8(truncatingIfNeeded: seed >> 8),
                UInt8(truncatingIfNeeded: seed >> 16),
                255
            )
        }
    }

    private func makeSolidImage(width: Int, height: Int, red: UInt8, green: UInt8, blue: UInt8) throws -> CGImage {
        try makeImage(width: width, height: height) { _, _ in
            (red, green, blue, 255)
        }
    }

    private func makeImage(
        width: Int,
        height: Int,
        colorSpace: CGColorSpace? = nil,
        pixel: (Int, Int) -> (UInt8, UInt8, UInt8, UInt8)
    ) throws -> CGImage {
        let colorSpace = colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let bytesPerRow = width * 4
        var bytes = [UInt8](repeating: 0, count: bytesPerRow * height)

        for y in 0..<height {
            for x in 0..<width {
                let value = pixel(x, y)
                let offset = y * bytesPerRow + x * 4
                bytes[offset] = value.0
                bytes[offset + 1] = value.1
                bytes[offset + 2] = value.2
                bytes[offset + 3] = value.3
            }
        }

        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(
                    rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
                        | CGBitmapInfo.byteOrder32Big.rawValue
                ),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              )
        else {
            throw XCTSkip("Could not create test CGImage")
        }
        return image
    }

    private func pixelRGBA(in image: CGImage, x: Int, y: Int) throws -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        let width = image.width
        let height = image.height
        let bytesPerRow = width * 4
        var bytes = [UInt8](repeating: 0, count: bytesPerRow * height)
        let rendered = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard rendered, x >= 0, y >= 0, x < width, y < height else {
            throw XCTSkip("Could not sample test image pixel")
        }
        let offset = y * bytesPerRow + x * 4
        return (bytes[offset], bytes[offset + 1], bytes[offset + 2], bytes[offset + 3])
    }

    private func makeQRCodeImage(payload: String, size: Int) throws -> CGImage {
        let generator = CIFilter(name: "CIQRCodeGenerator")
        generator?.setValue(payload.data(using: .utf8), forKey: "inputMessage")
        generator?.setValue("M", forKey: "inputCorrectionLevel")

        guard let qrImage = generator?.outputImage else {
            throw NSError(domain: "ParcelTests", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Could not generate QR image.",
            ])
        }

        let falseColor = CIFilter(name: "CIFalseColor")
        falseColor?.setValue(qrImage, forKey: kCIInputImageKey)
        falseColor?.setValue(CIColor.black, forKey: "inputColor0")
        falseColor?.setValue(CIColor.white, forKey: "inputColor1")

        guard let colored = falseColor?.outputImage else {
            throw NSError(domain: "ParcelTests", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Could not color QR image.",
            ])
        }

        let scale = CGFloat(size) / colored.extent.width
        let scaled = colored.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let image = CIContext().createCGImage(scaled, from: scaled.extent) else {
            throw NSError(domain: "ParcelTests", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Could not render QR image.",
            ])
        }
        return image
    }

    private func makeTestRecordingMP4(at url: URL, frameCount: Int) async throws {
        let writer = try LegacyRecordingWriter(url: url, videoSize: CGSize(width: 64, height: 48), monoAudio: true)
        for frame in 0..<frameCount {
            writer.receiveSampleForTesting(
                try makeVideoSampleBuffer(width: 64, height: 48, frame: frame),
                type: .screen
            )
        }
        writer.flushSamplesForTesting()
        try await writer.finish()
    }

    private func makeVideoSampleBuffer(width: Int, height: Int, frame: Int) throws -> CMSampleBuffer {
        var pixelBuffer: CVPixelBuffer?
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        ]
        let pixelStatus = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )
        guard pixelStatus == kCVReturnSuccess, let pixelBuffer else {
            throw NSError(domain: "ParcelTests", code: Int(pixelStatus), userInfo: [
                NSLocalizedDescriptionKey: "Could not create test pixel buffer.",
            ])
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw NSError(domain: "ParcelTests", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Could not lock test pixel buffer.",
            ])
        }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let bytes = baseAddress.assumingMemoryBound(to: UInt8.self)
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                bytes[offset] = UInt8((frame * 13 + x) % 256)
                bytes[offset + 1] = UInt8((frame * 7 + y) % 256)
                bytes[offset + 2] = UInt8((x + y) % 256)
                bytes[offset + 3] = 255
            }
        }

        var formatDescription: CMVideoFormatDescription?
        let formatStatus = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )
        guard formatStatus == noErr, let formatDescription else {
            throw NSError(domain: "ParcelTests", code: Int(formatStatus), userInfo: [
                NSLocalizedDescriptionKey: "Could not create video format description.",
            ])
        }

        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: CMTime(value: CMTimeValue(frame), timescale: 30),
            decodeTimeStamp: .invalid
        )
        var sampleBuffer: CMSampleBuffer?
        let sampleStatus = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDescription,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )
        guard sampleStatus == noErr, let sampleBuffer else {
            throw NSError(domain: "ParcelTests", code: Int(sampleStatus), userInfo: [
                NSLocalizedDescriptionKey: "Could not create video sample buffer.",
            ])
        }
        return sampleBuffer
    }

    private func imageSourceType(for data: Data) -> String? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceGetType(source) as String?
    }
}
