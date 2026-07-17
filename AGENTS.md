# Parcel — Build Guide & Fixed Decisions

Parcel is an **original, from-scratch macOS Capture / annotation / recording app** from the
Parable ecosystem, built in SwiftUI. It is **not** a fork of anything. The open-source app
*macshot* is used **only** as a feature-parity reference — no code, assets, naming, or glossary
terms are copied from it.

**Bundle ID:** `dev.parable.Parcel` · **Display name:** Parcel

---

## Hard constraints (non-negotiable — do not relitigate)

1. **No LLM / network AI calls anywhere.** Not Codex, not OpenAI, nothing that sends data
   off-device for AI. On-device Apple frameworks only (Vision; local Apple Intelligence APIs
   only if stable on-device). Any "AI" feature must be provably local.
2. **macOS 13.0+**, Apple Silicon + Intel.
3. **SwiftUI everywhere except where AppKit is structurally required** (capture overlay window,
   editor/preferences window hosting, global hotkey). Don't reach for AppKit out of habit; don't
   avoid it where SwiftUI genuinely can't do the job.
4. **MIT licensed. Original icon/name/glossary.** Zero macshot naming or asset reuse.

---

## Glossary (canonical terms — use these exact words in code AND UI copy; no synonyms)

| Term | Meaning |
|------|---------|
| **Capture** | The act of grabbing pixels, and the resulting frozen full-resolution image of a display. |
| **Selection** | The user-chosen region within a Capture — either a dragged rectangle or a snapped window. |
| **Overlay** | The borderless, full-screen selection UI (an `NSPanel` hosting SwiftUI) shown to make a Selection. |
| **Editor** | The window where a Capture is marked up and then copied/saved. |
| **Annotation** | A single mark-up object: Arrow, Rectangle, Text, Pencil, Censor. One editable object. |
| **Tool** | The active annotation mode used to create Annotations (also the toolbar item that selects it). |
| **Canvas** | The drawing surface inside the Editor: the base Capture plus its Annotations. |
| **Layer** | The ordered stack of Annotations composited over the Capture. "Layer order" = z-order. |

Banned synonyms that must NOT drift into code/UI: *screenshot* (use **Capture**), *shape/markup object*
as a class name (use **Annotation**), *crop box* (use **Selection**), *drawing/mask* (use **Censor**).

---

## Current phase

**Phases 1–4: IMPLEMENTED.** v1.0 Release build on macOS 26 with sandbox, Sparkle, onboarding,
configurable hotkey, Supabase upload (user-configured), ellipse Tool, erase censor mode, and
on-device translation (macOS 15+). macOS 13 capture/recording fallbacks remain written-but-untested
on the primary dev machine — see `docs/MACOS13_VM_QA.md`.

**Phase 2 render pipeline (the load-bearing design — do not regress):**
raw Capture → adjusted base (CI chain; neutral short-circuits to raw) → censor blur/pixelate
derive FROM the adjusted base → AnnotatedCanvas (spotlight dim backdrop first, then vectors,
then censors; Capture-point coords) → BeautifyCanvas wrapper (pass-through when disabled) →
ImageRenderer at capture.scale. One composition drives display AND export ("on screen === saved").

**Coordinate rule (everywhere):** `capturePoint = viewPoint/scale − innerOrigin`, where
`innerOrigin = effectiveSettings.innerOrigin = (padding, padding + chromeHeight)`. Overlays
(selection box/handles/text editor) use the inverse `+ innerOrigin·scale` on their `.position()`.

**Undo scope:** the ⌘Z stack covers annotation content ONLY (create/delete/move/resize/restyle).
Adjustments and Beautify are document-level settings, out of the stack, with panel Resets.

**Still not implemented (v1.1+):** WebP/AVIF codecs, cloud history sync, analytics, cross-device
handoff, capture templates, iOS/iPadOS companion, App Store submission.

**Release infra:** `Scripts/release.sh`, GitHub Actions, Next.js site at `Website/`, Sparkle appcast
at `Website/public/appcast.xml`. Manual QA matrix: `docs/QA_CHECKLIST.md`.

---

## Architecture decisions (Phase 1)

- **Global hotkey: Carbon `RegisterEventHotKey`** (`Hotkeys/HotKeyManager.swift`), not `CGEventTap`.
  It is the mechanism `KeyboardShortcuts`/`HotKey` use and needs **no Accessibility permission** —
  eliminating a whole class of "permissions dead-end." Default: **⌘⇧2** (⌘⇧3/4/5 are macOS system
  shortcuts). **Configurable in Preferences** via `HotKeyRecorder`.
- **Capture model: freeze-then-select.** On hotkey we capture a full-res image of every display
  via ScreenCaptureKit, show it frozen in the Overlay, and crop the Selection from those frozen
  pixels. No live-overlay window exclusion needed; gives the "frozen screen" feel.
- **Pixel capture: ScreenCaptureKit.** `SCScreenshotManager.captureImage` on macOS 14+;
  an `SCStream` single-frame fallback for macOS 13 (`Capture/CaptureEngine.swift`). No
  `CGWindowListCreateImage`. NOTE: only the 14+ path is exercised on the current dev machine
  (macOS 26); the 13.0 SCStream fallback is written-but-untested here.
- **Overlay: `NSPanel`** (borderless, `.screenSaver` level) hosting SwiftUI via `NSHostingView`
  (`Capture/OverlayWindow.swift` + `OverlayController.swift`). One panel per display. Esc cancels
  via a local key monitor; drag = region Selection; single click on a highlighted window = window snap.
- **Menu bar: SwiftUI `MenuBarExtra`** + `LSUIElement` (no dock icon). App activation policy is
  `.accessory`. Custom menu bar icon in `Assets.xcassets/MenuBarIcon`.
- **Editor / Preferences windows: AppKit-managed `NSWindow` + `NSHostingView`** (not SwiftUI
  `WindowGroup`/`Settings`), because we open them programmatically with a captured image payload
  and want explicit lifecycle control on 13.0+.

## Sandbox

Release builds are **sandboxed** (`Resources/Parcel.entitlements`):
- `com.apple.security.app-sandbox` = `true`
- `com.apple.security.files.user-selected.read-write` for Save panel

Use a **stable Developer ID** signing identity so Screen Recording TCC persists across updates.
Debug ad-hoc builds may need permission re-grant after rebuild.

## Concurrency

`SWIFT_VERSION = 5.0` (Swift 5 language mode on the Swift 6 compiler) to avoid strict-concurrency
friction during Phase 1. UI/AppKit types are annotated `@MainActor` regardless. Revisit moving to
Swift 6 language mode once the surface is stable.

---

## Project layout

```
project.yml                     XcodeGen spec — the .xcodeproj is generated, not committed.
Sources/Parcel/
  App/          ParcelApp (@main), AppDelegate, AppCoordinator, AppIdentity migration
  Onboarding/   WelcomeWindowController (first-run flow)
  MenuBar/      MenuBarContent (SwiftUI menu)
  Hotkeys/      HotKeyManager (Carbon global hotkey)
  Permissions/  ScreenRecordingPermission (TCC check/request + guidance)
  Capture/      Models, CaptureEngine (ScreenCaptureKit), CaptureController,
                OverlayWindow, OverlayController, SelectionOverlayView, ScrollCapture
  Editor/       EditorModel, EditorWindowController, EditorView, output/beautify/adjustment support
  History/      Local re-editable Capture document store and History window
  Recording/    ScreenCaptureKit recorder, macOS 13 AVFoundation fallback, trim/export window
  Vision/       On-device OCR, QR, face, translation, and local redaction analysis
  Upload/       Supabase Storage upload (optional, user-configured)
  Preferences/  PreferencesWindowController, PreferencesView, HotKeyRecorder
  Support/      Extensions, AppIdentity
  Resources/    Info.plist, Parcel.entitlements, PrivacyInfo.xcprivacy, Assets.xcassets
Scripts/        release.sh, generate_icons.sh, ExportOptions.plist
Website/         Next.js marketing site (parcel.parable.dev)
docs/           QA_CHECKLIST.md, MACOS13_VM_QA.md
```

### Build

```
xcodegen generate          # regenerate Parcel.xcodeproj from project.yml
xcodebuild -project Parcel.xcodeproj -scheme Parcel -configuration Debug build
```

Run the built `.app` (from DerivedData) directly; on first launch complete onboarding and grant
**Screen Recording** in System Settings → Privacy & Security, then reopen Parcel.

Release: `DEVELOPMENT_TEAM=… ./Scripts/release.sh`
