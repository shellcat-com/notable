# Parcel architecture

Parcel is a menu bar macOS app: **Capture → Overlay Selection → Editor → copy/save/upload**.

## Render pipeline (do not regress)

```
raw Capture
  → adjusted base (Core Image; neutral short-circuits)
  → censor blur/pixelate derived from adjusted base
  → AnnotatedCanvas (spotlight dim, vectors, censors)
  → BeautifyCanvas wrapper
  → ImageRenderer at capture.scale
```

Display and export share one composition (**on screen === saved**).

## Coordinate rule

```
capturePoint = viewPoint / scale − innerOrigin
innerOrigin = effectiveSettings.innerOrigin = (padding, padding + chromeHeight)
```

Overlays use the inverse: `+ innerOrigin · scale` on `.position()`.

## Module map

| Area | Role |
|------|------|
| `App/` | Coordinator, lifecycle, window wiring |
| `Hotkeys/` | Carbon global hotkey + Preferences storage |
| `Capture/` | ScreenCaptureKit freeze, Overlay, scroll stitch |
| `Editor/` | Tools, Canvas, Beautify, Adjustments, export |
| `History/` | Disk-backed re-editable documents |
| `Recording/` | MP4 + trim + GIF |
| `Vision/` | On-device OCR, faces, QR, translation |
| `Upload/` | Supabase Storage REST client |
| `Preferences/` | TCC guidance, hotkey recorder, upload config |

## Undo scope

⌘Z covers **annotation content only** (create, delete, move, resize, restyle, layer order, rotation). Adjustments and Beautify are document settings with panel Resets.

## Sandbox

Dev builds are non-sandboxed for TCC stability during iteration. See AGENTS.md for release hardening checklist.
