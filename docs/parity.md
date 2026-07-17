# macshot vs Parcel — Feature Parity

Working checklist for beating [macshot](https://macshot.io/) while keeping Parcel's local-first privacy story.

| Capability | macshot | Parcel | Status | Owner |
|---|---|---|---|---|
| Region / window capture | Yes | Yes | Done | — |
| Global hotkey | Configurable | Configurable (Preferences) | Done | App |
| Ellipse annotation | Yes | Yes | Done | App |
| Arrow ×5 styles | Yes | Yes | Done | — |
| Censor blur / pixelate / solid | Yes | Yes | Done | — |
| Smart erase censor | Yes | Yes | Done | App |
| Click-to-edit annotations | Yes | Yes | Done | — |
| Layer z-order controls | Yes | Yes | Done | App |
| Annotation rotation | Yes | Yes | Done | App |
| Undo / redo | Yes | Yes (annotations) | Done | — |
| Scroll capture | Overlay + preview | Overlay + menu bar | Done | App |
| MP4 / GIF recording + trim | Yes | Yes | Done | — |
| Recording fps presets | Up to 120fps | 30 / 60 / 120 | Done | App |
| Beautify (30 gradients) | Yes | Yes | Done | — |
| Brand kits | Partial | Yes | **Better** | — |
| OCR | Yes (Vision) | Yes (Vision) | Done | — |
| OCR translate | Cloud / Google | On-device (macOS 15+) | Done | App |
| PII / face censor | Yes | Yes (local regex + Vision) | Done | — |
| Cloud upload | Drive / imgbb / S3 | Supabase Storage | Done | App |
| Re-editable history | Yes | Yes (disk-backed) | **Better** | — |
| HEIC / TIFF export | Partial | Yes | **Better** | — |
| Configurable hotkeys UI | Yes | Yes | Done | App |
| Homebrew install | Yes | Cask in repo | Done | Repo |
| Marketing site | macshot.io | Astro + Parable | Done | Web |
| 40-language app UI | Yes | English (Phase 2) | Deferred | — |
| Network LLM / AI search | Google AI | **Never** (hard constraint) | N/A | — |
| iOS companion | No | No | Deferred | — |

## Parcel differentiators (market harder than macshot)

1. **No network AI** — Vision, OCR, translation, and redaction stay on-device.
2. **Re-editable local History** — full annotation + adjustment + beautify state restored.
3. **Beautify brand kits** — named presets saved locally.
4. **Honest UX** — no fake upload buttons; Supabase only when configured.
5. **Native SwiftUI** — no Electron, no web views in the app shell.

## Verification

- [ ] Capture region, window snap, all-display stitch
- [ ] Every Tool creates and exports correctly (including Ellipse, erase Censor)
- [ ] Layer order + rotation on selected Annotation
- [ ] Hotkey change in Preferences persists across relaunch
- [ ] Scroll capture from Overlay + menu bar finish flow
- [ ] Supabase upload copies URL to clipboard
- [ ] On-device translation (macOS 15+) in Vision panel
- [ ] Website deploys to static host with download link
