#!/usr/bin/env bash
# Verify that a release-gate handoff folder contains enough evidence to close external gates.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EVIDENCE_DIR="${1:-$ROOT/qa-evidence/final-ship-2026-08-12/release-gate-handoff-current}"
EXPECTED_TEAM="${EXPECTED_DEVELOPMENT_TEAM:-QFH99B6X5V}"

passes=0
failures=0
gates=0

pass() { echo "PASS: $*"; passes=$((passes + 1)); }
fail() { echo "FAIL: $*"; failures=$((failures + 1)); }
gate() { echo "GATE: $*"; gates=$((gates + 1)); }

require_file() {
  local label="$1"
  local relpath="$2"
  local path="$EVIDENCE_DIR/$relpath"
  if [[ -s "$path" ]]; then
    pass "$label evidence exists ($relpath)"
  else
    gate "$label evidence is missing or empty ($relpath)"
  fi
}

require_clean_summary() {
  local label="$1"
  local relpath="$2"
  local path="$EVIDENCE_DIR/$relpath"
  if [[ ! -s "$path" ]]; then
    gate "$label log is missing or empty ($relpath)"
    return
  fi
  if grep -Eq -- '--- [0-9]+ passed, 0 failed, 0 gated ---' "$path"; then
    pass "$label reports 0 failed / 0 gated"
  elif grep -Eq -- '--- [0-9]+ passed, [1-9][0-9]* failed,' "$path"; then
    fail "$label reports failures ($relpath)"
  elif grep -Eq -- '--- [0-9]+ passed, 0 failed, [1-9][0-9]* gated ---' "$path"; then
    gate "$label still reports gated items ($relpath)"
  else
    gate "$label does not contain a recognized pass/fail/gate summary ($relpath)"
  fi
}

require_plain_success_summary() {
  local label="$1"
  local relpath="$2"
  local path="$EVIDENCE_DIR/$relpath"
  if [[ ! -s "$path" ]]; then
    gate "$label log is missing or empty ($relpath)"
    return
  fi
  if grep -Eq -- '--- [0-9]+ passed, 0 failed ---' "$path"; then
    pass "$label reports 0 failed"
  elif grep -Eq -- '--- [0-9]+ passed, [1-9][0-9]* failed ---' "$path"; then
    fail "$label reports failures ($relpath)"
  else
    gate "$label does not contain a recognized pass/fail summary ($relpath)"
  fi
}

require_contains() {
  local label="$1"
  local relpath="$2"
  local pattern="$3"
  local path="$EVIDENCE_DIR/$relpath"
  if [[ ! -s "$path" ]]; then
    gate "$label evidence is missing or empty ($relpath)"
  elif grep -Eiq -- "$pattern" "$path"; then
    pass "$label evidence matches expected content"
  else
    gate "$label evidence does not match expected content ($relpath)"
  fi
}

require_manual_verified() {
  local label="$1"
  local relpath="$2"
  local path="$EVIDENCE_DIR/$relpath"
  if [[ ! -s "$path" ]]; then
    gate "$label manual proof is missing or empty ($relpath)"
  elif grep -Eiq '^VERIFIED:[[:space:]]*yes[[:space:]]*$' "$path"; then
    local missing=0
    for field in 'macOS:' 'Parcel app path:' 'Final ZIP SHA-256:' 'Tester:' 'Date:'; do
      if ! grep -Eiq "^$field[[:space:]]*[^[:space:]]" "$path"; then
        missing=1
      fi
    done
    if (( missing == 0 )); then
      pass "$label manual proof is marked VERIFIED: yes with required metadata"
    else
      gate "$label manual proof is verified but missing required metadata fields ($relpath)"
    fi
  else
    gate "$label manual proof must include a line exactly like 'VERIFIED: yes' ($relpath)"
  fi
}

echo "==> Parcel release gate evidence verification"
echo "    evidence: $EVIDENCE_DIR"

if [[ -d "$EVIDENCE_DIR" ]]; then
  pass "Evidence directory exists"
else
  fail "Evidence directory is missing: $EVIDENCE_DIR"
  echo
  echo "--- $passes passed, $failures failed, $gates gated ---"
  exit 2
fi

require_file "Handoff packet" "RELEASE_GATE_HANDOFF.md"
require_contains "Developer ID identity" "release/developer-id-identity.txt" "Developer ID Application:.*\\($EXPECTED_TEAM\\)"
require_clean_summary "Final release preflight" "release/gate-preflight-final.log"
require_contains "Public release build" "release/release-final.log" "==> Done:|Website artifact:"
require_contains "Notarization" "release/notarization.log" "accepted|status:[[:space:]]*Accepted"
require_contains "Stapling validation" "release/stapler-validate.log" "worked|accepted|valid"
require_contains "Gatekeeper validation" "release/spctl-final.log" "accepted"
require_clean_summary "Final public ZIP verifier" "release/verify-release-final.log"
require_contains "Final appcast signing" "release/appcast-update-final.log" "sparkle:edSignature=|sparkle:edSignature=\"[^\"]+\""
require_file "Website final build" "website/build-final.log"
require_plain_success_summary "Website export artifact verifier" "website/export-artifact-final.log"
require_manual_verified "Screen Recording TCC" "ui/screen-recording-final.md"
require_manual_verified "Computer Use UI" "ui/computer-use-final.md"
require_manual_verified "Second-display QA" "hardware/second-display-final.md"
require_manual_verified "Live Supabase QA" "upload/supabase-live-final.md"
require_manual_verified "macOS 13 fallback QA" "macos13/fallback-final.md"

echo
echo "--- $passes passed, $failures failed, $gates gated ---"
if (( failures > 0 )); then
  exit 2
fi
if (( gates > 0 )); then
  exit 1
fi
