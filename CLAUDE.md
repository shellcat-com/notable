# Notable — Build Guide & Fixed Decisions

Notable is an **original, from-scratch macOS screenshot / annotation / (later) recording app**
in SwiftUI. It is **not** a fork of anything. The open-source app *macshot* is used **only** as a
feature-parity reference — no code, assets, naming, or glossary terms are copied from it.

> "Notable" is a working codename. It collides with an existing note-taking app, so a final
> original name + icon is required before any public repo. Do not treat the name as settled.

---

## Hard constraints (non-negotiable — do not relitigate)

1. **No LLM / network AI calls anywhere.** Not Claude, not OpenAI, nothing that sends data
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

**Phase 2 — annotation depth + Beautify: IMPLEMENTED, pending hands-on verification.**
Phase 1 (capture → annotate → copy/save loop) is complete. Phase 2 adds: Arrow ×5 styles,
Censor ×3 modes (blur/pixelate/solid), Number/Stamp/Highlighter/Measure/Spotlight Tools,
restyle-existing (selection-aware toolbar, coalesced undo), Loupe + Eyedropper utility Tools,
Beautify (30 gradients, padding, radius, shadow, window chrome), and on-device Core Image
Adjustments (7 params + presets).

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

**Still OUT of scope (Phase 3+):** scroll capture, recording, OCR, upload/sync, cross-device
handoff, capture templates.

---

## Architecture decisions (Phase 1)

- **Global hotkey: Carbon `RegisterEventHotKey`** (`Hotkeys/HotKeyManager.swift`), not `CGEventTap`.
  It is the mechanism `KeyboardShortcuts`/`HotKey` use and needs **no Accessibility permission** —
  eliminating a whole class of "permissions dead-end." Default: **⌘⇧2** (⌘⇧3/4/5 are macOS system
  shortcuts). Configurable UI is a later task; the binding lives in one place for now.
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
  `.accessory`. Menu bar icon is an SF Symbol placeholder — **flagged for a custom icon pass**.
- **Editor / Preferences windows: AppKit-managed `NSWindow` + `NSHostingView`** (not SwiftUI
  `WindowGroup`/`Settings`), because we open them programmatically with a captured image payload
  and want explicit lifecycle control on 13.0+.

## Sandbox

Phase 1 dev builds are **non-sandboxed** (`Resources/Notable.entitlements` has
`com.apple.security.app-sandbox = false`). Reason: Screen Recording TCC permission is keyed to the
code signature and churns on every ad-hoc-signed rebuild under the sandbox — that would break
"usable daily today." Hardening checklist before any public release:
1. Set `com.apple.security.app-sandbox` = `true`.
2. Add `com.apple.security.files.user-selected.read-write` (Save panel).
3. Re-test that ScreenCaptureKit + the Save panel still work under sandbox.
4. Adopt a stable signing identity so the TCC grant persists across rebuilds.

## Concurrency

`SWIFT_VERSION = 5.0` (Swift 5 language mode on the Swift 6 compiler) to avoid strict-concurrency
friction during Phase 1. UI/AppKit types are annotated `@MainActor` regardless. Revisit moving to
Swift 6 language mode once the surface is stable.

---

## Project layout

```
project.yml                     XcodeGen spec — the .xcodeproj is generated, not committed.
Sources/Notable/
  App/          NotableApp (@main), AppDelegate, AppCoordinator (app state + wiring)
  MenuBar/      MenuBarContent (SwiftUI menu)
  Hotkeys/      HotKeyManager (Carbon global hotkey)
  Permissions/  ScreenRecordingPermission (TCC check/request + guidance)
  Capture/      Models, CaptureEngine (ScreenCaptureKit), CaptureController,
                OverlayWindow, OverlayController, SelectionOverlayView
  Editor/       EditorModel, EditorWindowController, EditorView
  Preferences/  PreferencesWindowController, PreferencesView
  Support/      Extensions (NSScreen/​CGRect helpers)
  Resources/    Info.plist, Notable.entitlements, Assets.xcassets
```

### Build

```
xcodegen generate          # regenerate Notable.xcodeproj from project.yml (after adding/moving files)
xcodebuild -project Notable.xcodeproj -scheme Notable -configuration Debug build
```

Run the built `.app` (from DerivedData) directly; on first Capture, grant **Screen Recording** in
System Settings → Privacy & Security, then reopen Notable.
