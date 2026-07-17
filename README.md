# Notable

A native macOS Capture and annotation tool, built from scratch in SwiftUI. Capture a region or a
window, mark it up, and get it onto your clipboard or saved as a file — fast, on-device, no cloud.

> **Working codename.** "Notable" is a placeholder; a final original name + icon is pending.

## Status

**Phase 1 — core loop: verified (Debug build).** Hotkey capture → frozen Overlay → region /
window-snap Selection → Editor → copy / save. Builds cleanly on macOS 26; Screen Recording
permission required for live Capture.

**Phase 2 — annotation depth + Beautify: verified (code + build).** Arrow ×5 styles, Censor ×3
modes, Number, Stamp, Highlighter, Measure, Spotlight, Loupe, Eyedropper, selection-aware
restyling, Beautify (30 gradients), and on-device Core Image Adjustments. Editor ⌘C/⌘S/⌘Z work
from canvas focus via a local key monitor.

**Phase 3 and local Phase 4: verified (code + build).** Manual Vision-assisted scroll stitching,
MP4 display recording with trim and GIF export, local editable history (including output format),
Vision OCR/QR/face detection, local PII/face Censoring, PNG/JPEG/HEIC/TIFF output, and saved
Beautify brand kits.

**Audit fixes applied:** user-visible errors for failed all-display stitch, empty Selection crop,
and history restore/create failures; delay Capture countdown in the menu bar; scroll Capture
guidance text; `outputFormat` persisted in history documents.

**Known limitations:** macOS 13 ScreenCaptureKit/AVFoundation fallbacks are written but untested
on this machine; menu bar icon is still an SF Symbol placeholder; hotkey is fixed at ⌘⇧2; scroll
Capture is menu-bar-driven (no in-overlay UI).

**No network AI, ever** — a hard project constraint. Any later AI-adjacent feature must stay
provably on-device through Apple frameworks.

## Prompt audit

Already built from the attached prompt:

- Menu bar app shell, no dock icon, default **⌘⇧2** global Capture hotkey.
- ScreenCaptureKit freeze-then-select flow with one Overlay per display.
- Region Selection, window hover highlight, one-click window snap, aspect presets, and edge snap.
- Delayed Capture and a stitched all-display Capture.
- Editor with editable Annotations: Arrow, Rectangle, Text, Pencil, Censor, Number, Stamp,
  Highlighter, Measure, and Spotlight.
- Utility Tools: Loupe and Eyedropper.
- Undo / redo for Annotation content, including move, resize, delete, create, and restyle.
- Copy to clipboard and PNG/JPEG/HEIC/TIFF save with remembered last-used folder.
- Beautify frame: 30 gradients, padding, corner radius, shadow, and window chrome.
- On-device Core Image Adjustments with presets.
- Local named Beautify brand kits and a re-editable local Capture history.
- On-device Vision OCR, QR reading, face detection, and optional sensitive-text/face Censoring.
- Manual scroll Capture with Vision registration plus pixel-overlap validation.
- MP4 display recording (system audio; microphone/click highlights on macOS 15+), trim, MP4 export,
  and local GIF export.

Remaining later-phase work from the master prompt:

- Final original name and icon before any public release.
- Full interactive QA pass on a Mac with Screen Recording granted (Capture, scroll stitch,
  recording/audio, exports, history restore) — automated GUI testing was blocked by TCC in CI.
- Translation, smart erase, and WebP/AVIF codecs.
- Supabase configuration, authenticated short-link upload, analytics, and optional history sync.
- Cross-device handoff / iOS-iPadOS companion app.
- Production marketing site deployment (a **draft static site** lives in [`Website/`](Website/) with
  a local Debug zip — not signed, not notarized, codename branding).

## Requirements

- macOS 13.0+
- Xcode 15+ (developed against Xcode 26)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Build & run

```sh
xcodegen generate
xcodebuild -project Notable.xcodeproj -scheme Notable -configuration Debug \
  -derivedDataPath .derivedData build
open .derivedData/Build/Products/Debug/Notable.app
```

Notable lives in the menu bar (no dock icon). Press **⌘⇧2** to capture. On first capture, grant
**Screen Recording** in System Settings → Privacy & Security, then reopen Notable.

## License

MIT — see [LICENSE](LICENSE).
