<div align="center">

<h1>Parcel</h1>

<p>
  <strong>The native macOS Capture studio from <a href="https://parable.dev">Parable</a>.</strong><br>
  Freeze your screen, annotate with fourteen tools, censor with on-device Vision, beautify for ship-ready output,<br>
  record, scroll-capture, and upload — when <em>you</em> choose. No cloud AI, ever.
</p>

<p>
  <a href="https://parcel-zeta-silk.vercel.app"><img alt="Live site" src="https://img.shields.io/badge/live_site-parcel--zeta--silk.vercel.app-8b5cf6?style=flat-square&labelColor=1a1a1a"></a>
  <img alt="macOS 13+" src="https://img.shields.io/badge/macOS-13%2B-000?style=flat-square&logo=apple&logoColor=white&labelColor=1a1a1a">
  <img alt="14 tools" src="https://img.shields.io/badge/tools-14-ec4899?style=flat-square&labelColor=1a1a1a">
  <img alt="0 cloud AI" src="https://img.shields.io/badge/cloud_AI-0-5ee4b5?style=flat-square&labelColor=1a1a1a">
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/license-MIT-22c55e?style=flat-square&labelColor=1a1a1a"></a>
</p>

<p>
  <a href="https://parcel-zeta-silk.vercel.app"><b>Website</b></a>
  &nbsp;·&nbsp;
  <a href="https://parcel-zeta-silk.vercel.app/downloads/Parcel.zip"><b>Download</b></a>
  &nbsp;·&nbsp;
  <a href="docs/README.md">Docs</a>
  &nbsp;·&nbsp;
  <a href="docs/architecture.md">Architecture</a>
  &nbsp;·&nbsp;
  <a href="CONTRIBUTING.md">Contributing</a>
</p>

<a href="https://parcel-zeta-silk.vercel.app">
  <img src=".github/assets/hero.svg" alt="Parcel — Capture, mark up, and ship" width="100%">
</a>

</div>

<br>

## Why Parcel

| | |
|---|---|
| **Native, not a web wrapper** | SwiftUI + ScreenCaptureKit + AppKit where structurally required. Menu bar app with a global hotkey — no Electron, no dock icon clutter. |
| **Private by default** | OCR, face detection, translation, and regex redaction use Apple on-device frameworks only. Upload is optional Supabase Storage you configure yourself. |
| **On screen = saved** | One render pipeline drives the Editor display and export. What you see in Beautify and Adjustments is exactly what copies or saves. |
| **Built for daily work** | Freeze-then-select Capture, window snap, scroll stitch, MP4 recording, re-editable history, configurable hotkeys, and Sparkle updates. |

<br>

## See it in action

<table>
<tr>
<td width="50%">
  <a href="docs/architecture.md"><img src=".github/assets/capture-flow.svg" alt="Parcel capture and render pipeline"></a>
</td>
<td width="50%">
  <a href="docs/parity.md"><img src=".github/assets/toolkit.svg" alt="Parcel annotation toolkit"></a>
</td>
</tr>
<tr>
<td align="center"><b>Capture → Select → Editor → Ship</b><br><a href="docs/architecture.md">Architecture →</a></td>
<td align="center"><b>14 tools + Vision + Beautify</b><br><a href="docs/parity.md">Feature parity →</a></td>
</tr>
</table>

<br>

## Quick start

### Requirements

- macOS **13.0+** (Apple Silicon + Intel)
- Xcode **15+** (developed on Xcode 26)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

### Build & run

```sh
xcodegen generate
xcodebuild -project Parcel.xcodeproj -scheme Parcel -configuration Debug \
  -derivedDataPath .derivedData build CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES
open .derivedData/Build/Products/Debug/Parcel.app
```

Parcel lives in the **menu bar**. On first launch, complete the welcome flow, grant **Screen Recording**, then **quit and reopen**.

Default Capture hotkey: **⌘⇧2** (configurable in Preferences).

<br>

## Release

Signed, notarized builds via [`Scripts/release.sh`](Scripts/release.sh):

```sh
DEVELOPMENT_TEAM=XXXXXXXXXX \
APPLE_ID=you@example.com \
APPLE_APP_PASSWORD=xxxx-xxxx-xxxx-xxxx \
./Scripts/release.sh
```

Set `SKIP_NOTARIZE=1` for unsigned local Release builds. Tag `v*` triggers [`.github/workflows/release.yml`](.github/workflows/release.yml).

<br>

## Project layout

```
Sources/Parcel/
  App/           Coordinator, lifecycle, onboarding
  Capture/       ScreenCaptureKit freeze, Overlay, scroll stitch
  Editor/        Tools, Canvas, Beautify, Adjustments, export
  History/       Disk-backed re-editable Capture documents
  Recording/     MP4 + trim + GIF export
  Vision/        On-device OCR, faces, QR, translation
  Upload/        Supabase Storage REST client
  Hotkeys/       Carbon global hotkey + Preferences
Website/         Next.js marketing site (parcel-zeta-silk.vercel.app)
docs/            Architecture, parity, QA, integrations
Scripts/         release.sh, generate_icons.sh
Casks/           Homebrew cask (parcel.rb)
```

The `.xcodeproj` is **generated** from [`project.yml`](project.yml) — run `xcodegen generate` after adding or moving files.

<br>

## Docs

| Doc | What it covers |
|-----|----------------|
| [docs/README.md](docs/README.md) | Documentation index |
| [docs/architecture.md](docs/architecture.md) | Render pipeline, coordinates, module map |
| [docs/parity.md](docs/parity.md) | macshot feature parity checklist |
| [docs/QA_CHECKLIST.md](docs/QA_CHECKLIST.md) | Manual verification matrix |
| [docs/integrations.md](docs/integrations.md) | GitHub, Vercel, Supabase, MCP setup |
| [AGENTS.md](AGENTS.md) | Glossary, constraints, build guide for agents |

<br>

## Built with

<p>
  <img alt="Swift" src="https://img.shields.io/badge/Swift-SwiftUI-F05138?style=flat-square&logo=swift&logoColor=white">
  <img alt="ScreenCaptureKit" src="https://img.shields.io/badge/ScreenCaptureKit-native-000?style=flat-square&logo=apple&logoColor=white&labelColor=1a1a1a">
  <img alt="Vision" src="https://img.shields.io/badge/Vision-on--device-000?style=flat-square&logo=apple&logoColor=white&labelColor=1a1a1a">
  <img alt="Core Image" src="https://img.shields.io/badge/Core_Image-adjustments-000?style=flat-square&logo=apple&logoColor=white&labelColor=1a1a1a">
  <img alt="Next.js" src="https://img.shields.io/badge/Next.js-16-000?style=flat-square&logo=next.js&logoColor=white&labelColor=1a1a1a">
  <img alt="React" src="https://img.shields.io/badge/React-19-61DAFB?style=flat-square&logo=react&logoColor=black">
  <img alt="Tailwind CSS" src="https://img.shields.io/badge/Tailwind-v4-38B2AC?style=flat-square&logo=tailwindcss&logoColor=white">
  <img alt="Motion" src="https://img.shields.io/badge/Motion-animations-8b5cf6?style=flat-square&labelColor=1a1a1a">
  <img alt="Sparkle" src="https://img.shields.io/badge/Sparkle-updates-000?style=flat-square&labelColor=1a1a1a">
</p>

<br>

## Contributing

Issues and pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) first — especially the glossary in [AGENTS.md](AGENTS.md) and the QA checklist for Capture/recording changes.

**Hard rule:** no network LLM / AI calls. On-device Apple frameworks only.

<br>

## License

Parcel is released under the [MIT License](LICENSE) — free and open. Built by [Parable](https://parable.dev).

<br>

<div align="center">
  <sub>Part of the Parable ecosystem · <a href="https://github.com/bswxyz/parable">Parable components & templates</a> · <a href="https://parcel-zeta-silk.vercel.app">parcel-zeta-silk.vercel.app</a></sub>
</div>
