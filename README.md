# Parcel

A native macOS Capture and annotation tool from [Parable](https://parable.dev), built in SwiftUI. Capture a region or window, mark it up, and copy or save — fast, on-device, no cloud AI.

**Tagline:** Capture, mark up, and ship.

## Status

**v1.0 — Phases 1–4 complete.** Hotkey capture → frozen Overlay → Selection → Editor → copy/save. Full annotation toolkit, Beautify, Adjustments, scroll capture, recording, local history, Vision OCR/QR/face, PII/face censoring, optional Supabase upload, configurable hotkey, Sparkle auto-update, sandboxed Release builds.

See [docs/QA_CHECKLIST.md](docs/QA_CHECKLIST.md) for the manual verification matrix.

**No network AI, ever** — OCR, face detection, translation, and redaction use Apple on-device frameworks only.

## Features

- Menu bar app (no dock icon), configurable global Capture hotkey (default ⌘⇧2)
- ScreenCaptureKit freeze-then-select with window snap, aspect presets, delay, all-display stitch
- 14 annotation Tools including ellipse and erase censor mode
- Beautify (30 gradients), Adjustments, brand kits, PNG/JPEG/HEIC/TIFF export
- Scroll capture with on-device Vision stitching
- MP4 display recording with trim and GIF export
- Re-editable local Capture history
- Optional Supabase Storage upload (user-configured)
- First-run onboarding and Sparkle updates

## Requirements

- macOS 13.0+
- Xcode 15+ (developed against Xcode 26)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Build & run

```sh
xcodegen generate
xcodebuild -project Parcel.xcodeproj -scheme Parcel -configuration Debug \
  -derivedDataPath .derivedData build CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES
open .derivedData/Build/Products/Debug/Parcel.app
```

Parcel lives in the menu bar. On first launch, complete the welcome flow and grant **Screen Recording**, then quit and reopen.

## Release

```sh
DEVELOPMENT_TEAM=XXXXXXXXXX \
APPLE_ID=you@example.com \
APPLE_APP_PASSWORD=xxxx-xxxx-xxxx-xxxx \
./Scripts/release.sh
```

Set `SKIP_NOTARIZE=1` for unsigned local Release builds. See [Scripts/release.sh](Scripts/release.sh).

## Website

Marketing site in [`Website/`](Website/) — Astro + Tailwind, live at **[parcel.parable.dev](https://parcel.parable.dev)**. Repo: **[github.com/bswxyz/notable](https://github.com/bswxyz/notable)**.

Connected services (GitHub, Vercel, Supabase, Mobbin, Higgsfield): [docs/integrations.md](docs/integrations.md).

## License

MIT — see [LICENSE](LICENSE).
