# Parcel — Manual QA Checklist

Run on macOS 26 with **Screen Recording** granted. Use a **Release + sandboxed** build for final sign-off.

## 2026-08-12 Final Verification Status

Evidence folder: `qa-evidence/final-ship-2026-08-12/`

- Build: PASS — `xcodegen generate`, Debug, and Release builds completed.
- Release app checks: PASS for bundle ID, display name, minimum macOS version, menu-bar mode, Sparkle feed URL, universal binary, sandbox entitlement, no `get-task-allow`, Sparkle public key, and release smoke checks.
- Export codecs: PASS for selected PNG/JPEG/HEIC/TIFF/WebP output paths; PNG/JPEG/TIFF use system bitmap encoders, HEIC uses ImageIO, and WebP uses local libwebp.
- Recording writer/export: PASS for deterministic low-level MP4 finalization with H.264 video, AAC audio, and `moov` metadata; production writer unit coverage verifies pause skip behavior and temporary-file install before replacing the final output; trim model coverage exports readable MP4 and animated GIF outputs without a save panel.
- History: PASS for create/restore/save/delete, filter predicate, and retention pruning against the persisted local index.
- No-network-AI invariant: PASS — `Scripts/verify-no-network-ai.sh` reports no cloud/network AI identifiers, network client APIs limited to optional Supabase upload, and Apple local Vision/Translation framework use.
- Website: PASS for `npm run lint` and `npm run build`.
- Website export artifact: PASS — `Scripts/verify-website-export-artifact.sh` confirms static `Website/out` contains byte-identical `downloads/Parcel.zip` and `appcast.xml` from `Website/public`.
- Appcast structure: PASS — `Scripts/verify-release.sh` validates well-formed XML, feed title, parseable `pubDate`, `sparkle:os`, enclosure type, version/build, and download URL.
- Release script syntax: PASS — `Scripts/final-local-qa.sh` validates the release/appcast/preflight shell scripts with `bash -n`.
- Workflow syntax: PASS — `local-qa-current/release/workflow-syntax.log` parses GitHub workflow YAML and validates each embedded `run:` block with `bash -n`.
- CI non-gated coverage: PASS — push/PR CI runs script syntax, no-network-AI verification, Debug build, `ParcelUnit`, website lint, and website build.
- GitHub release signing/setup: PASS/GATED — tag-release CI has explicit `contents: write`, imports a base64 Developer ID Application `.p12` into an ephemeral keychain, removes the temporary `.p12`, runs the same release preflight/build/notary/appcast verifier path, builds and verifies the website export payload, then creates the GitHub Release; final release still gates until the certificate/notary/manual-QA secrets are configured.
- Release preflight hook: PASS/GATED — public `Scripts/release.sh` runs `Scripts/verify-release-gates.sh` before archive/export work and exits early when release-machine gates are missing.
- Appcast updater: PASS/GATED — dry-run with a fake Sparkle signer derives version/build/title/pubDate from a temp app ZIP, writes ZIP length/signature into a temp appcast, rejects malformed appcast input without modifying it, and leaves `Website/public/appcast.xml` unchanged; final real appcast update remains gated until the notarized ZIP exists.
- Sparkle public key consistency: PASS — source `SUPublicEDKey`, the Sparkle Keychain account public key, and the current website ZIP app key match.
- Real Sparkle signing dry-run: PASS — temp-copy signing uses the installed Sparkle `sign_update`, derives app metadata, updates a temp appcast, matches ZIP length, populates an EdDSA signature, verifies it against the ZIP, and leaves the real appcast unchanged.
- Release gate preflight: PASS/GATED — `Scripts/verify-release-gates.sh` checks Developer ID, notary credentials, Sparkle signing material, Screen Recording proof, second-display access, Supabase live credentials, and macOS 13 VM availability before a public ZIP attempt.
- Release gate handoff: PASS/GATED — `Scripts/write-release-gate-handoff.sh` writes a release-machine evidence packet for the external gates that cannot be closed on this machine.
- Release gate evidence verifier: PASS/GATED — `Scripts/verify-release-gate-evidence.sh` checks completed handoff folders and currently reports 2 pass / 0 fail / 15 gated on the local packet.
- Release gate evidence verifier self-test: PASS — synthetic complete evidence passes, missing manual metadata gates, and failed final logs fail.
- Local QA runner: PASS/GATED — `Scripts/final-local-qa.sh` completed build, unit, media, website/export, release-gate preflight, and release-verifier stages; only credential/environment gates remain.
- Ship status summary: PASS — `Scripts/ship-status.sh` summarizes the final evidence folder into local completion, public-release unblocked percentage, and remaining gates.
- Public claims audit: PASS/GATED — `qa-evidence/final-ship-2026-08-12/CLAIMS_AUDIT.md` maps README, parity, and checklist claims to direct evidence or explicit gates; no contradictory claim evidence was found.
- Release verifier: PASS/GATED — `Scripts/verify-release.sh` reports 23 pass / 0 fail / 5 gated on the current website ZIP.
- XCTest host stability: PASS — app-hosted `ParcelUnit` launches skip coordinator, Sparkle, hotkey, and onboarding side effects, so the final harness reaches XCTest reliably.
- Unit tests: PASS — `ParcelUnit` covers 51 local model tests: export-format claims, selected export encoder containers, sRGB export conversion, Retina scale-down Capture resizing, Capture preference defaults/toggles, shutter sound feedback policy, extra Capture Area hotkey bindings, Selection aspect preset cycling/ratio geometry/Shift bypass, window snap hit testing, all-display stitch desktop arrangement, countdown display/DND policy behavior, Pin opacity/close gesture mapping, Pin lock/visibility state, recently-closed restore stack behavior, clipboard image import, print payload sizing/pagination, share payload item/anchor behavior, production recording writer finalization/pause behavior, recording temporary-file install, recording trim MP4/GIF export, recording max-resolution geometry, keystroke HUD label/PiP placement behavior, previous Capture/recording area preference state, Scroll Capture vertical/horizontal stitching and no-overlap rejection, window Capture matte removal, brand kit save/reload/remove persistence, color swatch persistence/dedupe/capping, smart highlighter snap-to-text-box behavior, Quick Access shortcut/swipe mapping, 14-Tool inventory, Arrow/Censor style inventories, Censor erase outside-ring Retina sampling, URL-scheme actions, after-Capture action planning, hotkey/recording preference models, OCR strip-line-break formatting, WebP bytes, `.parcel` round-trip, History create/restore/save/delete/filter/retention prune, Upload disabled/not-configured behavior, Supabase upload request/success URL handling, Supabase HTTP error handling, local Vision QR detection and Capture-point coordinate mapping, local PII classification, annotation undo/redo + Layer order, document settings outside undo, transform remapping, crop transform remapping, expand/combine transform placement, and filename templates.
- UI automation: PARTIAL — app launch and menu contents passed; capture/recording UI tests are blocked until Screen Recording is granted to the exact test/release app path.
- Computer Use: BLOCKED — `node_repl` + `@oai/sky` can inspect a normal System Settings window, proving the runtime is alive, but Parcel bundle-id targeting is ambiguous because several local builds share `dev.parable.Parcel`; exact disposable app-path targeting and SystemUIServer/menu-bar targeting time out. Refreshed evidence is captured at `qa-evidence/final-ship-2026-08-12/local-qa-current/ui/computer-use-sky-refresh-current.md`, with prior details in `computer-use-sky-normal-window-sanity-current.md`, `computer-use-sky-focused-probes-current.md`, the earlier Parcel state JSON files, and the timeout log.
- Public ZIP release: BLOCKED — no Developer ID Application identity and no notary credentials. Current website ZIP is Apple Development signed and rejected by Gatekeeper; the real Sparkle appcast signature should be generated only after the final notarized ZIP exists.
- Hardware/service gates: BLOCKED — second display, live Supabase credentials, and macOS 13 VM were unavailable.

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

- [ ] Adjustments panel: change brightness/contrast — Canvas updates
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
- [ ] Translate (macOS 26+) — on-device translation in Vision panel
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

- [x] Local mock: disabled/not-configured path returns a user-facing configuration error
- [x] Local mock: configured upload builds the expected Supabase Storage request and public URL
- [x] Local mock: bad-credential/HTTP error includes status code and response body
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

## 13. v1.1–v1.6 Parity Smoke

- [ ] Capture Previous Area (menu / ⌘⇧5) after one region Capture
- [ ] Preferences: Ask for name + after-Capture Copy / Pin / Editor toggles
- [ ] Hold ⇧ while dragging Selection — aspect preset ignored
- [ ] Recording: countdown, pause, resume, max resolution, mono audio
- [ ] Quick Access: ⌘C ⌘S ⌘E ⌘W; swipe down discards
- [ ] Pin: scroll opacity, middle-click close, Hide/Show Overlays, Close All Pins
- [ ] Restore Recently Closed + Open from Clipboard
- [ ] History: filter, Pin from row, retention prune
- [ ] `parcel://capture/region` and `parcel://capture/previous` (URL scheme enabled)
- [ ] Editor: transform menu (rotate/flip/expand), WebP export, Print, Share
- [ ] Save / open `.parcel` project round-trip
- [ ] Filename template tokens apply on Save / Upload

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
