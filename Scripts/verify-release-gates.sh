#!/usr/bin/env bash
# Preflight the external credentials, tools, and hardware needed for a public Parcel release.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXPECTED_TEAM="${EXPECTED_DEVELOPMENT_TEAM:-QFH99B6X5V}"
SPARKLE_ACCOUNT="${SPARKLE_KEYCHAIN_ACCOUNT:-parcel.parable.dev}"
WEBSITE_ZIP="$ROOT/Website/public/downloads/Parcel.zip"
APPCAST_PATH="${APPCAST_PATH:-$ROOT/Website/public/appcast.xml}"

passes=0
failures=0
gates=0

pass() { echo "PASS: $*"; passes=$((passes + 1)); }
fail() { echo "FAIL: $*"; failures=$((failures + 1)); }
gate() { echo "GATE: $*"; gates=$((gates + 1)); }

find_sign_update() {
  if [[ -n "${SPARKLE_SIGN_UPDATE:-}" && -x "$SPARKLE_SIGN_UPDATE" ]]; then
    echo "$SPARKLE_SIGN_UPDATE"
    return 0
  fi
  if command -v sign_update >/dev/null 2>&1; then
    command -v sign_update
    return 0
  fi
  local candidates=(
    "$ROOT/.derivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"
    "$ROOT/.derivedData-release/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"
  )
  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

echo "==> Parcel release gate preflight"
echo "    expected team: $EXPECTED_TEAM"

for tool in xcodegen xcodebuild security codesign ditto; do
  if command -v "$tool" >/dev/null 2>&1; then
    pass "$tool available"
  else
    fail "$tool is missing from PATH"
  fi
done

if xcrun -f notarytool >/dev/null 2>&1; then
  pass "notarytool available"
else
  fail "notarytool is missing"
fi

if xcrun -f stapler >/dev/null 2>&1; then
  pass "stapler available"
else
  fail "stapler is missing"
fi

identities="$(security find-identity -v -p codesigning 2>/dev/null || true)"
developer_id_lines="$(echo "$identities" | grep 'Developer ID Application:' || true)"
if [[ -n "$developer_id_lines" ]]; then
  pass "Developer ID Application identity installed"
  if echo "$developer_id_lines" | grep -q "($EXPECTED_TEAM)"; then
    pass "Developer ID identity matches team $EXPECTED_TEAM"
  else
    gate "Developer ID identity does not match expected team $EXPECTED_TEAM"
  fi
else
  gate "Developer ID Application identity is not installed"
fi

if [[ -n "${DEVELOPMENT_TEAM:-}" ]]; then
  if [[ "$DEVELOPMENT_TEAM" == "$EXPECTED_TEAM" ]]; then
    pass "DEVELOPMENT_TEAM is set to $EXPECTED_TEAM"
  else
    gate "DEVELOPMENT_TEAM is '$DEVELOPMENT_TEAM', expected '$EXPECTED_TEAM'"
  fi
else
  gate "DEVELOPMENT_TEAM is not set"
fi

if [[ -n "${NOTARYTOOL_PROFILE:-}" ]]; then
  if xcrun notarytool history --keychain-profile "$NOTARYTOOL_PROFILE" >/dev/null 2>&1; then
    pass "Notary keychain profile '$NOTARYTOOL_PROFILE' is available"
  else
    gate "Notary keychain profile '$NOTARYTOOL_PROFILE' is unavailable; run: xcrun notarytool store-credentials $NOTARYTOOL_PROFILE"
  fi
elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_PASSWORD:-}" && -n "${DEVELOPMENT_TEAM:-}" ]]; then
  pass "Apple ID notary credentials are present in the environment"
else
  gate "Notary credentials are missing; set NOTARYTOOL_PROFILE or APPLE_ID + APPLE_APP_PASSWORD + DEVELOPMENT_TEAM"
fi

if sign_update_path="$(find_sign_update)"; then
  pass "Sparkle sign_update available at $sign_update_path"
else
  gate "Sparkle sign_update is not available; resolve packages or set SPARKLE_SIGN_UPDATE"
fi

if [[ -n "${SPARKLE_ED_PRIVATE_KEY:-}" ]]; then
  pass "SPARKLE_ED_PRIVATE_KEY is present"
elif [[ -n "${SPARKLE_ED_KEY_FILE:-}" && -f "${SPARKLE_ED_KEY_FILE:-}" ]]; then
  pass "SPARKLE_ED_KEY_FILE exists"
elif security find-generic-password -a "$SPARKLE_ACCOUNT" >/dev/null 2>&1; then
  pass "Sparkle EdDSA key appears to exist in Keychain account '$SPARKLE_ACCOUNT'"
else
  gate "Sparkle EdDSA private key is unavailable; set SPARKLE_ED_PRIVATE_KEY, SPARKLE_ED_KEY_FILE, or import account '$SPARKLE_ACCOUNT'"
fi

if [[ -f "$WEBSITE_ZIP" && -w "$WEBSITE_ZIP" ]]; then
  pass "Website ZIP exists and is writable"
else
  gate "Website ZIP is missing or not writable: $WEBSITE_ZIP"
fi

if [[ -f "$APPCAST_PATH" && -w "$APPCAST_PATH" ]]; then
  pass "Appcast exists and is writable"
else
  gate "Appcast is missing or not writable: $APPCAST_PATH"
fi

if [[ "${PARCEL_SCREEN_RECORDING_VERIFIED:-}" == "1" ]]; then
  pass "Screen Recording was manually verified for the exact release/test app path"
else
  gate "Screen Recording must be granted and manually verified for the exact release/test app path"
fi

if [[ "${PARCEL_COMPUTER_USE_VERIFIED:-}" == "1" ]]; then
  pass "Computer Use UI proof was manually verified for the exact release/test app path"
else
  gate "Computer Use UI proof must be manually verified for the exact release/test app path"
fi

if [[ "${PARCEL_SECOND_DISPLAY_VERIFIED:-}" == "1" ]]; then
  pass "Second-display QA was manually verified"
else
  display_count="$(system_profiler SPDisplaysDataType 2>/dev/null | grep -c 'Resolution:' || true)"
  if [[ "${display_count:-0}" -ge 2 ]]; then
    gate "Second display detected ($display_count displays), but PARCEL_SECOND_DISPLAY_VERIFIED=1 is required after manual QA"
  else
    gate "Second-display QA requires an external display or PARCEL_SECOND_DISPLAY_VERIFIED=1"
  fi
fi

if [[ -n "${PARCEL_SUPABASE_URL:-}" && -n "${PARCEL_SUPABASE_ANON_KEY:-}" && -n "${PARCEL_SUPABASE_BUCKET:-}" ]]; then
  pass "Supabase live-test credentials are present in the environment"
  if [[ "${PARCEL_SUPABASE_LIVE_VERIFIED:-}" == "1" ]]; then
    pass "Live Supabase upload QA was manually verified"
  else
    gate "Live Supabase upload QA requires PARCEL_SUPABASE_LIVE_VERIFIED=1 after manual success/error testing"
  fi
else
  gate "Live Supabase upload QA needs PARCEL_SUPABASE_URL, PARCEL_SUPABASE_ANON_KEY, and PARCEL_SUPABASE_BUCKET"
fi

if [[ "${PARCEL_MACOS13_VM_VERIFIED:-}" == "1" ]]; then
  pass "macOS 13 fallback QA was manually verified"
else
  gate "macOS 13 fallback QA requires a VM or secondary macOS 13 machine"
fi

echo
echo "--- $passes passed, $failures failed, $gates gated ---"
if (( failures > 0 )); then
  exit 2
fi
if (( gates > 0 )); then
  exit 1
fi
