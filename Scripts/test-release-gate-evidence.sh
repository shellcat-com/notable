#!/usr/bin/env bash
# Self-test the release-gate evidence verifier with synthetic complete and incomplete packets.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/parcel-gate-evidence-test.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

passes=0
failures=0

pass() { echo "PASS: $*"; passes=$((passes + 1)); }
fail() { echo "FAIL: $*"; failures=$((failures + 1)); }

write_manual_note() {
  local path="$1"
  local verified="$2"
  cat >"$path" <<EOF
# Manual proof

VERIFIED: $verified

macOS: 26.0
Parcel app path: /Applications/Parcel.app
Packet ZIP SHA-256: packet-hash
Final ZIP SHA-256: final-hash
Tester: Release QA
Date: 2026-08-12

Evidence notes:
- Synthetic verifier self-test note.
EOF
}

write_complete_packet() {
  local dir="$1"
  mkdir -p "$dir"/{release,website,ui,hardware,upload,macos13}

  printf '# Parcel Release Gate Handoff\n' >"$dir/RELEASE_GATE_HANDOFF.md"
  printf '1) Developer ID Application: Parcel Release (QFH99B6X5V)\n' >"$dir/release/developer-id-identity.txt"
  printf '%s\n' '--- 18 passed, 0 failed, 0 gated ---' >"$dir/release/gate-preflight-final.log"
  printf '==> Done: /tmp/Parcel.zip\n    Website artifact: Website/public/downloads/Parcel.zip\n' >"$dir/release/release-final.log"
  printf 'status: Accepted\n' >"$dir/release/notarization.log"
  printf 'The staple and validate action worked!\n' >"$dir/release/stapler-validate.log"
  printf 'Parcel.app: accepted\n' >"$dir/release/spctl-final.log"
  printf '%s\n' '--- 28 passed, 0 failed, 0 gated ---' >"$dir/release/verify-release-final.log"
  printf 'sparkle:edSignature=abc123\n' >"$dir/release/appcast-update-final.log"
  printf 'Website build completed\n' >"$dir/website/build-final.log"
  printf '%s\n' '--- 7 passed, 0 failed ---' >"$dir/website/export-artifact-final.log"

  write_manual_note "$dir/ui/screen-recording-final.md" yes
  write_manual_note "$dir/ui/computer-use-final.md" yes
  write_manual_note "$dir/hardware/second-display-final.md" yes
  write_manual_note "$dir/upload/supabase-live-final.md" yes
  write_manual_note "$dir/macos13/fallback-final.md" yes
}

complete_dir="$tmp_dir/complete"
write_complete_packet "$complete_dir"
if Scripts/verify-release-gate-evidence.sh "$complete_dir" >"$tmp_dir/complete.log" 2>&1; then
  if grep -Eq -- '--- [0-9]+ passed, 0 failed, 0 gated ---' "$tmp_dir/complete.log"; then
    pass "complete synthetic packet passes"
  else
    fail "complete synthetic packet did not report 0 gated"
  fi
else
  cat "$tmp_dir/complete.log" >&2
  fail "complete synthetic packet verifier exited nonzero"
fi

missing_metadata_dir="$tmp_dir/missing-metadata"
cp -R "$complete_dir" "$missing_metadata_dir"
sed -i.bak 's/^Final ZIP SHA-256: final-hash$/Final ZIP SHA-256:/' "$missing_metadata_dir/ui/screen-recording-final.md"
if Scripts/verify-release-gate-evidence.sh "$missing_metadata_dir" >"$tmp_dir/missing-metadata.log" 2>&1; then
  fail "missing metadata packet unexpectedly passed"
elif grep -Eq -- '--- [0-9]+ passed, 0 failed, [1-9][0-9]* gated ---' "$tmp_dir/missing-metadata.log"; then
  pass "missing manual metadata is gated, not failed"
else
  cat "$tmp_dir/missing-metadata.log" >&2
  fail "missing metadata packet did not report gated status"
fi

failed_log_dir="$tmp_dir/failed-log"
cp -R "$complete_dir" "$failed_log_dir"
printf '%s\n' '--- 20 passed, 1 failed, 0 gated ---' >"$failed_log_dir/release/verify-release-final.log"
if Scripts/verify-release-gate-evidence.sh "$failed_log_dir" >"$tmp_dir/failed-log.log" 2>&1; then
  fail "failed release log packet unexpectedly passed"
elif grep -Eq -- '--- [0-9]+ passed, [1-9][0-9]* failed, [0-9]+ gated ---' "$tmp_dir/failed-log.log"; then
  pass "failed release log is treated as failure"
else
  cat "$tmp_dir/failed-log.log" >&2
  fail "failed release log packet did not report failure status"
fi

echo
echo "--- $passes passed, $failures failed ---"
if (( failures > 0 )); then
  exit 1
fi
