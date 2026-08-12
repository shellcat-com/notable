# Competitive parity — Parcel vs CleanShot / macshot

Working checklist for local-first Capture parity. Parcel keeps privacy differentiators and never ships network AI or a CleanShot Cloud clone.

## Decision

- **Local-first:** Capture / Editor / Recording / History / Overlay stay on-device
- **Upload:** user-configured Supabase only (no proprietary cloud, push, SSO, or view/comment social)
- **Glossary:** Capture, Selection, Overlay, Editor, Annotation, Tool, Canvas, Layer
- **Never:** network LLM, Raycast AI Chat, CleanShot trademarks/assets/copy

## Feature matrix (v1.1–v1.6 shipped in app)

| Capability | Status |
|---|---|
| Region / window / display / all-displays Capture | Done |
| Freeze-then-select Overlay + All-in-One bar | Done |
| Previous-area Capture | Done |
| Ask for name before Save | Done |
| After-Capture action matrix (copy / editor / pin / upload / save) | Done |
| Capture Area & … hotkeys + Previous ⌘⇧5 | Done |
| ⇧ Shift bypass aspect preset while dragging | Done |
| Scroll Capture (vertical + horizontal stitch) | Done |
| OCR Capture + Editor Vision (text / faces / QR / PII) | Done |
| Quick Access + keyboard shortcuts + swipe discard | Done |
| Pin + lock + opacity scroll + middle-click close + hide/close all | Done |
| Restore recently closed / open from clipboard | Done |
| Editor Annotations (arrow×5, shapes, text, pencil, censor, etc.) | Done |
| Capture transforms (crop / resize / rotate / flip / expand / combine) | Done |
| Color swatches + smart highlighter snap (on-device) | Done |
| Beautify + Adjustments + brand kits | Done |
| Recording pause/resume, countdown, max resolution, mono, DND | Done |
| Keystroke HUD + webcam PiP + GIF export | Done |
| History filter + retention + Pin from History | Done |
| `parcel://` URL scheme (disable in Preferences) | Done |
| Filename templates `{date}` `{time}` `{month}` `{index}` `{app}` `{window}` | Done |
| Export PNG / JPEG / HEIC / TIFF / WebP + sRGB option | Done |
| Print + Share + `.parcel` project files | Done |
| Shutter sound preference | Done |
| Recording previous area | Done |
| Keystroke HUD position preference | Done |
| Remove window Capture backdrop (matte) | Done |
| OCR strip line breaks preference | Done |

## Explicitly excluded

- CleanShot Cloud Pro (custom domain, branding, team SSO, push on view/comment, self-destruct product)
- Network AI / Raycast AI Chat
- App Store submission (tracked separately)
- 40-language UI (deferred)
- AVIF codec (deferred)

## Parcel differentiators

1. **No network AI** — Vision, OCR, translation, and redaction stay on-device
2. **Re-editable local History** — full annotation + adjustment + beautify state
3. **Beautify brand kits** — named presets saved locally
4. **Honest upload UX** — Supabase only when configured
5. **Native SwiftUI** — no Electron shell

## Verification smoke list

Claim-level release evidence is tracked in
`qa-evidence/final-ship-2026-08-12/CLAIMS_AUDIT.md`. The matrix above records implementation
status; the claim audit separates source/model evidence from gated UI, hardware, service, and
release-machine proof.

2026-08-12 local evidence: `ParcelUnit` covers URL-scheme action parsing, transform remapping,
selected PNG/JPEG/HEIC/TIFF/WebP export encoder containers, sRGB export conversion,
Retina scale-down Capture resizing, Selection aspect preset cycling/ratio geometry/Shift bypass,
expand/combine transform pixel and Annotation placement, Censor erase outside-ring Retina sampling,
WebP format metadata/bytes,
production recording writer finalization/pause behavior, recording max-resolution geometry,
countdown display/DND policy behavior,
keystroke HUD label/PiP placement behavior,
recording temporary-file install,
recording trim MP4/GIF export, Scroll Capture vertical/horizontal stitching and no-overlap
rejection, all-display stitch desktop arrangement, window Capture matte removal,
brand kit save/reload/remove persistence,
`.parcel` round-trip, History create/restore/save/delete/filter and retention prune, filename
template tokens, Capture preference defaults/toggles, extra Capture Area hotkey bindings,
shutter sound feedback policy, recently-closed restore stack behavior, clipboard image import,
window snap hit testing, Pin opacity/close gesture mapping, Pin lock/visibility state,
print payload sizing/pagination, share payload item/anchor behavior,
Quick Access shortcut/swipe mapping, Tool inventory, Arrow/Censor style inventories, Upload disabled/not-configured behavior,
mocked Supabase request/success/error handling, local PII classification, and hotkey/recording
preference models, plus after-Capture action planning, OCR strip-line-break formatting,
previous Capture/recording area preference state, color swatch persistence/dedupe/capping,
smart highlighter snap-to-text-box behavior, local Vision QR detection, and Capture-point coordinate
mapping.
`Scripts/verify-no-network-ai.sh` covers the no-network-AI source invariant. Screen Recording,
second-display, live Supabase upload, and macOS 13 fallback checks remain gated in
`docs/QA_CHECKLIST.md`.

- [ ] Previous area after one region Capture
- [ ] After-Capture toggles in Preferences
- [ ] ⌘⇧5 previous / ⌥⌘⇧C copy intent
- [ ] Hold ⇧ while dragging Selection (free aspect)
- [ ] Recording pause / resume / countdown
- [ ] Quick Access ⌘C ⌘S ⌘E ⌘W
- [ ] `parcel://capture/region` and `parcel://capture/previous`
- [ ] Editor transform menu + WebP save + `.parcel` round-trip
- [ ] History filter + retention prune
