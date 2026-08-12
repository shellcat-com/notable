#!/usr/bin/env bash
# Generate a release-machine handoff packet for the external gates that cannot be proven locally.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

STAMP="${STAMP:-$(date +%Y-%m-%d-%H%M%S)}"
EVIDENCE_DIR="${EVIDENCE_DIR:-$ROOT/qa-evidence/release-gate-handoff-$STAMP}"
HANDOFF_PATH="${HANDOFF_PATH:-$EVIDENCE_DIR/RELEASE_GATE_HANDOFF.md}"
WEBSITE_ZIP="${WEBSITE_ZIP:-$ROOT/Website/public/downloads/Parcel.zip}"

mkdir -p "$EVIDENCE_DIR"/{release,ui,hardware,upload,macos13,website}

classify_status() {
  local path="$1"
  if grep -Eq -- '--- [0-9]+ passed, 0 failed, 0 gated ---' "$path"; then
    echo "pass"
  elif grep -Eq -- '--- [0-9]+ passed, 0 failed, [1-9][0-9]* gated ---' "$path"; then
    echo "gated"
  else
    echo "fail"
  fi
}

preflight_log="$EVIDENCE_DIR/release/gate-preflight.log"
if Scripts/verify-release-gates.sh >"$preflight_log" 2>&1; then
  preflight_status="pass"
else
  preflight_status="$(classify_status "$preflight_log")"
fi

verify_log="$EVIDENCE_DIR/release/verify-release-current.log"
if Scripts/verify-release.sh "$WEBSITE_ZIP" >"$verify_log" 2>&1; then
  verify_status="pass"
else
  verify_status="$(classify_status "$verify_log")"
fi

short_sha="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
branch="$(git branch --show-current 2>/dev/null || echo unknown)"
generated_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
if [[ -n "$(git status --short 2>/dev/null || true)" ]]; then
  worktree_state="dirty"
else
  worktree_state="clean"
fi
if [[ -f "$WEBSITE_ZIP" ]]; then
  zip_sha="$(shasum -a 256 "$WEBSITE_ZIP" | awk '{print $1}')"
else
  zip_sha="missing"
fi

write_manual_template() {
  local relpath="$1"
  local title="$2"
  local checks="$3"
  local path="$EVIDENCE_DIR/$relpath"
  if [[ -e "$path" ]]; then
    if grep -Eiq '^VERIFIED:[[:space:]]*yes[[:space:]]*$' "$path"; then
      return
    fi
  fi

  cat >"$path" <<EOF
# $title

VERIFIED: no

macOS:
Parcel app path:
Packet ZIP SHA-256: $zip_sha
Final ZIP SHA-256:
Tester:
Date:

Required checks:
$checks

Evidence notes:
-
EOF
}

write_manual_template "ui/screen-recording-final.md" "Screen Recording TCC Proof" "- Exact final/test Parcel.app path is granted Screen Recording.
- Parcel was quit and reopened after permission change.
- Region Capture opens the Overlay instead of Preferences.
- Region Recording opens the recording Selection flow instead of Preferences."

write_manual_template "ui/computer-use-final.md" "Computer Use UI Proof" "- Menu bar opens and expected Capture/Recording/History/Preferences actions are visible.
- Overlay can be opened and cancelled.
- Editor opens from a Capture and exposes Tool/output controls.
- Preferences opens and hotkey/upload/recording settings are inspectable.
- History opens and displays/restores a local Capture.
- Recording flow reaches trim/export UI.
- Evidence was collected with node_repl + @oai/sky, or an equivalent release-machine manual proof is attached.
- If @oai/sky cannot drive Parcel on the release machine, include a normal-window sanity result and the exact Parcel app-path/SystemUIServer error output."

write_manual_template "hardware/second-display-final.md" "Second Display QA Proof" "- External display is connected and detected.
- Capture All Displays creates a stitched Capture containing both displays.
- Multi-display Overlay placement and cancellation work.
- Single-display behavior still works after disconnect/reconnect."

write_manual_template "upload/supabase-live-final.md" "Live Supabase QA Proof" "- Preferences accepts project URL, anon key, and bucket.
- Upload succeeds and copies a public URL.
- Public URL opens the uploaded Capture.
- Disabled/not-configured state blocks upload with a useful message.
- Bad credentials surface a useful error. Redact credentials from this note."

write_manual_template "macos13/fallback-final.md" "macOS 13 Fallback QA Proof" "- macOS 13 VM or secondary Mac is identified.
- Capture uses the SCStream fallback path.
- Recording uses the legacy AVFoundation writer path.
- Core flows pass: region Capture to Editor, all 14 Tools smoke, History restore.
- Any fallback-specific issue is linked or noted."

cat >"$HANDOFF_PATH" <<EOF
# Parcel Release Gate Handoff

Generated: $generated_at

Repository state:
- Branch: \`$branch\`
- Commit: \`$short_sha\`
- Worktree: \`$worktree_state\`
- Evidence folder: \`$EVIDENCE_DIR\`

Current automated gate checks:
- Release gate preflight: \`$preflight_status\` — \`release/gate-preflight.log\`
- Current website ZIP verifier: \`$verify_status\` — \`release/verify-release-current.log\`

Use this packet on the release-capable machine to close the external gates before publishing the
public website ZIP. Do not paste secrets into this file; capture only command output, screenshots,
or short notes that prove the gate was satisfied.

## Required Gate Evidence

| Gate | Required proof | Evidence path |
|---|---|---|
| Developer ID identity | \`security find-identity -v -p codesigning\` shows a \`Developer ID Application\` identity for the expected Team ID. | \`release/developer-id-identity.txt\` |
| Release preflight | \`Scripts/verify-release-gates.sh\` reports \`0 failed, 0 gated\`. | \`release/gate-preflight-final.log\` |
| Public release build | \`UPDATE_APPCAST=1 DEVELOPMENT_TEAM=... NOTARYTOOL_PROFILE=... Scripts/release.sh\` completes. | \`release/release-final.log\` |
| Notarization | \`notarytool submit --wait\` output includes accepted status. | \`release/notarization.log\` |
| Stapling | \`xcrun stapler validate build/export/Parcel.app\` succeeds. | \`release/stapler-validate.log\` |
| Gatekeeper | \`spctl -a -vvv -t install\` accepts the extracted final \`Parcel.app\`. | \`release/spctl-final.log\` |
| Final ZIP verifier | \`Scripts/verify-release.sh Website/public/downloads/Parcel.zip\` reports \`0 failed, 0 gated\`. | \`release/verify-release-final.log\` |
| Final appcast | \`Scripts/update-appcast.sh\` or release output shows non-placeholder length/signature for the final ZIP. | \`release/appcast-update-final.log\` |
| Website export payload | \`npm --prefix Website run build\` and \`Scripts/verify-website-export-artifact.sh\` pass after final ZIP/appcast update. | \`website/build-final.log\`, \`website/export-artifact-final.log\` |
| Screen Recording TCC | Exact final/test \`Parcel.app\` path is granted Screen Recording and Capture/Recording UI opens Overlay instead of Preferences. Include \`VERIFIED: yes\`. | \`ui/screen-recording-final.md\` |
| Computer Use UI pass | Menu bar, Overlay, Editor, Preferences, History, and Recording UI are driven with \`node_repl\` + \`@oai/sky\` or equivalent release-machine manual proof. Include \`VERIFIED: yes\`. | \`ui/computer-use-final.md\` |
| Second display | External display is connected and multi-display Capture/all-display stitch is verified. Include \`VERIFIED: yes\`. | \`hardware/second-display-final.md\` |
| Live Supabase | Upload success copies a public URL; bad credentials surface a useful error; disabled state blocks upload. Include \`VERIFIED: yes\`. | \`upload/supabase-live-final.md\` |
| macOS 13 fallback | macOS 13 VM/secondary Mac verifies SCStream Capture fallback, legacy recording writer fallback, and core Capture/Editor/History flows. Include \`VERIFIED: yes\`. | \`macos13/fallback-final.md\` |

## Release-Machine Command Sequence

\`\`\`sh
set -euo pipefail

export DEVELOPMENT_TEAM=QFH99B6X5V
export NOTARYTOOL_PROFILE=parcel-release
export SPARKLE_KEYCHAIN_ACCOUNT=parcel.parable.dev

# Set these to 1 only after the corresponding manual proof is captured.
export PARCEL_SCREEN_RECORDING_VERIFIED=1
export PARCEL_SECOND_DISPLAY_VERIFIED=1
export PARCEL_MACOS13_VM_VERIFIED=1

# Set for live upload QA.
export PARCEL_SUPABASE_URL=https://example.supabase.co
export PARCEL_SUPABASE_ANON_KEY=...
export PARCEL_SUPABASE_BUCKET=captures

Scripts/verify-release-gates.sh | tee "$EVIDENCE_DIR/release/gate-preflight-final.log"

UPDATE_APPCAST=1 \\
DEVELOPMENT_TEAM="\$DEVELOPMENT_TEAM" \\
NOTARYTOOL_PROFILE="\$NOTARYTOOL_PROFILE" \\
Scripts/release.sh | tee "$EVIDENCE_DIR/release/release-final.log"

Scripts/verify-release.sh Website/public/downloads/Parcel.zip \\
  | tee "$EVIDENCE_DIR/release/verify-release-final.log"
npm --prefix Website run build | tee "$EVIDENCE_DIR/website/build-final.log"
Scripts/verify-website-export-artifact.sh | tee "$EVIDENCE_DIR/website/export-artifact-final.log"

Scripts/verify-release-gate-evidence.sh "$EVIDENCE_DIR" \\
  | tee "$EVIDENCE_DIR/release-gate-evidence-final.log"
\`\`\`

## Manual UI Proof Notes

- Use the exact final/test \`Parcel.app\` path when granting Screen Recording.
- Quit and reopen Parcel after changing TCC permissions.
- Record the macOS version, app path, and final ZIP hash in each manual note.
- For Supabase, redact the anon key and project details if the evidence will be committed.
- Manual proof templates are created as \`VERIFIED: no\`. Change them to \`VERIFIED: yes\` only
  after all required checks and metadata fields are complete.
- Do not mark the release ready until \`Scripts/ship-status.sh\` and the final release verifier agree
  that all gates are closed.
EOF

echo "Wrote $HANDOFF_PATH"
echo "  preflight=$preflight_status"
echo "  release_verifier=$verify_status"
