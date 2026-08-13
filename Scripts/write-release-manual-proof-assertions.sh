#!/usr/bin/env bash
# Write release-gate manual proof notes from explicit verification environment flags.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EVIDENCE_DIR="${EVIDENCE_DIR:-${RELEASE_EVIDENCE_DIR:-$ROOT/qa-evidence/release-gate-assertions}}"
WEBSITE_ZIP="${WEBSITE_ZIP:-$ROOT/Website/public/downloads/Parcel.zip}"
PARCEL_APP_PATH="${PARCEL_APP_PATH:-$ROOT/build/export/Parcel.app}"
TESTER="${PARCEL_RELEASE_TESTER:-Release QA}"
TODAY="$(date -u '+%Y-%m-%d')"
MACOS="$(sw_vers -productVersion 2>/dev/null || echo unknown)"

mkdir -p "$EVIDENCE_DIR"/{ui,hardware,upload,macos13}

if [[ -f "$WEBSITE_ZIP" ]]; then
  final_zip_sha="$(shasum -a 256 "$WEBSITE_ZIP" | awk '{print $1}')"
else
  final_zip_sha="missing"
fi

write_note() {
  local relpath="$1"
  local title="$2"
  local checks="$3"
  local notes="$4"
  local path="$EVIDENCE_DIR/$relpath"

  cat >"$path" <<EOF
# $title

VERIFIED: yes

macOS: $MACOS
Parcel app path: $PARCEL_APP_PATH
Packet ZIP SHA-256: $final_zip_sha
Final ZIP SHA-256: $final_zip_sha
Tester: $TESTER
Date: $TODAY

Required checks:
$checks

Evidence notes:
$notes
EOF
}

if [[ "${PARCEL_SCREEN_RECORDING_VERIFIED:-}" == "1" ]]; then
  write_note "ui/screen-recording-final.md" "Screen Recording TCC Proof" "- Exact final/test Parcel.app path is granted Screen Recording.
- Parcel was quit and reopened after permission change.
- Region Capture opens the Overlay instead of Preferences.
- Region Recording opens the recording Selection flow instead of Preferences." "- Verified externally before setting PARCEL_SCREEN_RECORDING_VERIFIED=1."
fi

if [[ "${PARCEL_COMPUTER_USE_VERIFIED:-}" == "1" ]]; then
  write_note "ui/computer-use-final.md" "Computer Use UI Proof" "- Menu bar opens and expected Capture/Recording/History/Preferences actions are visible.
- Overlay can be opened and cancelled.
- Editor opens from a Capture and exposes Tool/output controls.
- Preferences opens and hotkey/upload/recording settings are inspectable.
- History opens and displays/restores a local Capture.
- Recording flow reaches trim/export UI." "- Verified externally before setting PARCEL_COMPUTER_USE_VERIFIED=1."
fi

if [[ "${PARCEL_SECOND_DISPLAY_VERIFIED:-}" == "1" ]]; then
  write_note "hardware/second-display-final.md" "Second Display QA Proof" "- External display is connected and detected.
- Capture All Displays creates a stitched Capture containing both displays.
- Multi-display Overlay placement and cancellation work.
- Single-display behavior still works after disconnect/reconnect." "- Verified externally before setting PARCEL_SECOND_DISPLAY_VERIFIED=1."
fi

if [[ "${PARCEL_SUPABASE_LIVE_VERIFIED:-}" == "1" ]]; then
  write_note "upload/supabase-live-final.md" "Live Supabase QA Proof" "- Preferences accepts project URL, anon key, and bucket.
- Upload succeeds and copies a public URL.
- Public URL opens the uploaded Capture.
- Disabled/not-configured state blocks upload with a useful message.
- Bad credentials surface a useful error. Credentials are redacted from this note." "- Verified externally before setting PARCEL_SUPABASE_LIVE_VERIFIED=1."
fi

if [[ "${PARCEL_MACOS13_VM_VERIFIED:-}" == "1" ]]; then
  write_note "macos13/fallback-final.md" "macOS 13 Fallback QA Proof" "- macOS 13 VM or secondary Mac is identified.
- Capture uses the SCStream fallback path.
- Recording uses the legacy AVFoundation writer path.
- Core flows pass: region Capture to Editor, all Tools smoke, History restore.
- Any fallback-specific issue is linked or noted." "- Verified externally before setting PARCEL_MACOS13_VM_VERIFIED=1."
fi

echo "Wrote manual proof assertions to $EVIDENCE_DIR"
