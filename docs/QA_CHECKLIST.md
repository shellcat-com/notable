# Parcel — Manual QA Checklist

Run on macOS 26 with **Screen Recording** granted. Use a **Release + sandboxed** build for final sign-off.

**Build under test:** _______________  
**Tester:** _______________  
**Date:** _______________

## Prerequisites

- [ ] Screen Recording granted for Parcel in System Settings → Privacy & Security
- [ ] App quit and reopened after granting permission
- [ ] At least one external display connected (for multi-monitor tests, optional)

---

## 1. Region Capture → Editor → Copy/Save

- [ ] Press ⌘⇧2 (or configured hotkey) — frozen Overlay appears on all displays
- [ ] Drag a region — dimensions label updates
- [ ] Release — Editor opens with cropped Capture
- [ ] ⌘C copies to clipboard — paste into Preview/Messages matches on-screen Canvas
- [ ] ⌘S saves PNG — file matches on-screen Canvas
- [ ] Save as JPEG, HEIC, TIFF — each format opens correctly

**Notes:** _______________

---

## 2. Window Snap + Aspect Presets + Delay

- [ ] Hover over window — highlight appears
- [ ] Single-click window — snaps Selection to window bounds
- [ ] Tab cycles aspect presets during drag
- [ ] Edge snap works near screen edges
- [ ] Menu: Capture After 3s — countdown in menu bar, then Overlay
- [ ] Capture After 5s / 10s work

**Notes:** _______________

---

## 3. All-Display Stitch

- [ ] Menu: Capture All Displays — stitched Capture opens in Editor
- [ ] Multi-monitor: all displays visible in stitch (if applicable)
- [ ] Error alert shown if stitch fails (simulate by disconnecting display mid-capture if possible)

**Notes:** _______________

---

## 4. Scroll Capture

- [ ] Menu: Scroll Capture — Overlay with scroll mode
- [ ] Drag tall region — initial frame captured
- [ ] Scroll source content, menu: Add Scroll Frame — frame count increments
- [ ] Menu: Finish Scroll Capture — stitched tall Capture in Editor
- [ ] Cancel scroll capture from menu — no orphan Editor
- [ ] Overlap validation error surfaced on bad frames

**Notes:** _______________

---

## 5. All 14 Tools + Undo/Redo

Tools: Select, Arrow, Rectangle, Ellipse, Text, Pencil, Censor, Number, Stamp, Highlighter, Measure, Spotlight, Loupe, Eyedropper

- [ ] Each Tool creates an Annotation
- [ ] Select: move and resize handles work
- [ ] Arrow: all 5 styles via toolbar
- [ ] Censor: Blur, Pixelate, Solid, Erase modes
- [ ] ⌘Z undoes last annotation change
- [ ] ⇧⌘Z redoes
- [ ] Adjustments changes are **not** in undo stack
- [ ] Beautify changes are **not** in undo stack

**Notes:** _______________

---

## 6. Adjustments + Beautify + Brand Kits

- [ ] Adjustments panel: change exposure/contrast — Canvas updates
- [ ] Preset applies correctly
- [ ] Reset restores neutral
- [ ] Beautify: enable gradient, padding, radius, shadow, chrome
- [ ] Export matches Beautify preview
- [ ] Save brand kit — persists after Editor close
- [ ] Load brand kit from panel

**Notes:** _______________

---

## 7. Vision (OCR / QR / Face / PII / Translation)

- [ ] Inspect Capture → Recognize Text — OCR results appear
- [ ] QR code in Capture — detected and readable
- [ ] Face in Capture — face regions detected
- [ ] Censor Detected Sensitive Text — PII regions censored
- [ ] Censor Detected Faces — face blur censors added
- [ ] Translate (macOS 15+) — on-device translation in Vision panel
- [ ] No network traffic during Vision (except optional Upload)

**Notes:** _______________

---

## 8. History Restore

- [ ] Open Editor — entry auto-created in History
- [ ] Add annotations, close Editor
- [ ] Menu: Capture History — entry listed with thumbnail
- [ ] Open entry — annotations, adjustments, beautify, output format restored
- [ ] Delete entry — removed from list
- [ ] Clear All — confirmation, list empty

**Notes:** _______________

---

## 9. Recording → Trim → Export

- [ ] Menu: Start Recording — save panel, recording begins
- [ ] Menu bar shows recording state / elapsed
- [ ] Stop Recording — trim Editor opens
- [ ] Trim in/out points — preview updates
- [ ] Export MP4 — plays with audio
- [ ] Export GIF — animates
- [ ] Microphone captured on macOS 15+ (if enabled in system)

**Notes:** _______________

---

## 10. Supabase Upload (Optional)

- [ ] Preferences: project URL, anon key, bucket configured
- [ ] Editor: Upload — progress shown
- [ ] Link copied to clipboard — URL opens in browser
- [ ] Upload disabled when not configured

**Notes:** _______________

---

## 11. Hotkey Rebind

- [ ] Preferences: record new shortcut (e.g. ⌘⇧P)
- [ ] New shortcut triggers Capture
- [ ] Quit and relaunch — shortcut still works

**Notes:** _______________

---

## 12. Permission Edge Cases

- [ ] Fresh install / revoke permission — Capture opens Preferences
- [ ] Recording without permission — opens Preferences (not generic alert only)
- [ ] Grant permission → Quit & Reopen — Capture works
- [ ] First-run onboarding shown once, skipped on relaunch

**Notes:** _______________

---

## macOS 13–14 Fallback (VM / secondary machine)

- [ ] Capture uses SCStream fallback (not SCScreenshotManager)
- [ ] Recording uses LegacyRecordingWriter (not SCRecordingOutput)
- [ ] Core flows 1, 5, 8 pass on macOS 13

**Notes:** _______________

---

## Release Hardening

- [ ] Sandbox enabled — Capture, recording, save panel, history all work
- [ ] Gatekeeper: notarized zip opens without right-click workaround
- [ ] Sparkle: Check for Updates finds appcast (no crash if offline)

**Notes:** _______________

---

## Sign-off

| Result | Count |
|--------|-------|
| Pass | ___ / 12 core + ___ release |
| Fail | ___ |
| Blocked | ___ |

**Ship recommendation:** ☐ Ready  ☐ Fix blockers  ☐ Defer macOS 13 claim
