#!/usr/bin/env bash
# Verify the public Parcel ZIP, embedded app, and Sparkle appcast are release-ready.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ZIP_PATH="${1:-$ROOT/Website/public/downloads/Parcel.zip}"
APPCAST_PATH="${APPCAST_PATH:-$ROOT/Website/public/appcast.xml}"
EXPECTED_DOWNLOAD_URL="${EXPECTED_DOWNLOAD_URL:-https://parcel.parable.dev/downloads/Parcel.zip}"
EXPECTED_BUNDLE_ID="${EXPECTED_BUNDLE_ID:-dev.parable.Parcel}"
EXPECTED_DISPLAY_NAME="${EXPECTED_DISPLAY_NAME:-Parcel}"
EXPECTED_MINIMUM_SYSTEM_VERSION="${EXPECTED_MINIMUM_SYSTEM_VERSION:-13.0}"
EXPECTED_FEED_URL="${EXPECTED_FEED_URL:-https://parcel.parable.dev/appcast.xml}"
EXPECTED_APPCAST_TITLE="${EXPECTED_APPCAST_TITLE:-Parcel}"
EXPECTED_APPCAST_OS="${EXPECTED_APPCAST_OS:-macos}"
EXPECTED_APPCAST_TYPE="${EXPECTED_APPCAST_TYPE:-application/octet-stream}"
SPARKLE_KEYCHAIN_ACCOUNT="${SPARKLE_KEYCHAIN_ACCOUNT:-parcel.parable.dev}"

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

validate_pub_date() {
  local value="$1"
  if date -j -f "%a, %d %b %Y %H:%M:%S %z" "$value" >/dev/null 2>&1; then
    return 0
  fi
  if date -d "$value" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

echo "==> Parcel release verification"
echo "    zip: $ZIP_PATH"
echo "    appcast: $APPCAST_PATH"

if [[ ! -f "$ZIP_PATH" ]]; then
  fail "ZIP is missing"
else
  pass "ZIP exists"
fi

tmp_dir=""
app_path=""
if [[ -f "$ZIP_PATH" ]]; then
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/parcel-release-verify.XXXXXX")"
  trap '[[ -n "$tmp_dir" ]] && rm -rf "$tmp_dir"' EXIT
  if ditto -x -k "$ZIP_PATH" "$tmp_dir"; then
    pass "ZIP extracts with ditto"
    app_path="$(find "$tmp_dir" -maxdepth 1 -name '*.app' -print -quit)"
    if [[ -n "$app_path" && -d "$app_path" ]]; then
      pass "ZIP contains an app bundle"
    else
      fail "ZIP does not contain a top-level app bundle"
    fi
  else
    fail "ZIP does not extract with ditto"
  fi
fi

if [[ -n "$app_path" ]]; then
  app_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_path/Contents/Info.plist" 2>/dev/null || true)"
  app_build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$app_path/Contents/Info.plist" 2>/dev/null || true)"
  app_bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Contents/Info.plist" 2>/dev/null || true)"
  app_display_name="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$app_path/Contents/Info.plist" 2>/dev/null || true)"
  app_bundle_name="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleName' "$app_path/Contents/Info.plist" 2>/dev/null || true)"
  app_minimum_system_version="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$app_path/Contents/Info.plist" 2>/dev/null || true)"
  app_lsui_element="$(/usr/libexec/PlistBuddy -c 'Print :LSUIElement' "$app_path/Contents/Info.plist" 2>/dev/null || true)"
  app_feed_url="$(/usr/libexec/PlistBuddy -c 'Print :SUFeedURL' "$app_path/Contents/Info.plist" 2>/dev/null || true)"

  if [[ "$app_bundle_id" == "$EXPECTED_BUNDLE_ID" ]]; then
    pass "Bundle ID matches expected value ($EXPECTED_BUNDLE_ID)"
  else
    fail "Bundle ID '$app_bundle_id' does not match expected '$EXPECTED_BUNDLE_ID'"
  fi

  if [[ "${app_display_name:-$app_bundle_name}" == "$EXPECTED_DISPLAY_NAME" ]]; then
    pass "Display name matches expected value ($EXPECTED_DISPLAY_NAME)"
  else
    fail "Display name '$app_display_name' / bundle name '$app_bundle_name' does not match expected '$EXPECTED_DISPLAY_NAME'"
  fi

  if [[ "$app_minimum_system_version" == "$EXPECTED_MINIMUM_SYSTEM_VERSION" ]]; then
    pass "Minimum macOS version matches expected value ($EXPECTED_MINIMUM_SYSTEM_VERSION)"
  else
    fail "Minimum macOS version '$app_minimum_system_version' does not match expected '$EXPECTED_MINIMUM_SYSTEM_VERSION'"
  fi

  if [[ "$app_lsui_element" == "true" ]]; then
    pass "App is configured as menu-bar-only (LSUIElement=true)"
  else
    fail "LSUIElement is '$app_lsui_element', expected true"
  fi

  if [[ "$app_feed_url" == "$EXPECTED_FEED_URL" ]]; then
    pass "Sparkle feed URL matches expected value"
  else
    fail "Sparkle feed URL '$app_feed_url' does not match expected '$EXPECTED_FEED_URL'"
  fi

  if file "$app_path/Contents/MacOS/Parcel" | grep -q "x86_64" &&
     file "$app_path/Contents/MacOS/Parcel" | grep -q "arm64"; then
    pass "App binary is universal x86_64 + arm64"
  else
    fail "App binary is not universal x86_64 + arm64"
  fi

  if codesign --verify --deep --strict "$app_path" >/dev/null 2>&1; then
    pass "Code signature verifies"
  else
    fail "Code signature verification failed"
  fi

  signature_details="$(codesign -dv --verbose=4 "$app_path" 2>&1 || true)"
  if echo "$signature_details" | grep -q "Authority=Developer ID Application:"; then
    pass "Signed with Developer ID Application"
  elif echo "$signature_details" | grep -q "Authority=Apple Development:"; then
    gate "Signed with Apple Development, not Developer ID Application"
  elif echo "$signature_details" | grep -q "Signature=adhoc"; then
    gate "Ad-hoc signed, not Developer ID Application"
  else
    gate "Developer ID Application signature not found"
  fi

  entitlements="$(codesign -d --entitlements :- "$app_path" 2>/dev/null || true)"
  entitlements_compact="$(echo "$entitlements" | tr -d '\n\t ')"
  if [[ "$entitlements_compact" == *"<key>com.apple.security.app-sandbox</key><true/>"* ]]; then
    pass "Sandbox entitlement present"
  else
    fail "Sandbox entitlement missing"
  fi
  if echo "$entitlements" | grep -q "get-task-allow"; then
    fail "Release entitlements contain get-task-allow"
  else
    pass "No get-task-allow entitlement"
  fi
  if [[ "$entitlements_compact" == *"<key>com.apple.security.files.user-selected.read-write</key><true/>"* ]]; then
    pass "User-selected read/write entitlement present"
  else
    fail "User-selected read/write entitlement missing"
  fi
  if [[ "$entitlements_compact" == *"<key>com.apple.security.network.client</key><true/>"* ]]; then
    pass "Network client entitlement present"
  else
    fail "Network client entitlement missing"
  fi

  if spctl -a -vv "$app_path" >/dev/null 2>&1; then
    pass "Gatekeeper accepts app"
  else
    gate "Gatekeeper rejects app"
  fi

  if xcrun stapler validate "$app_path" >/dev/null 2>&1; then
    pass "Stapled notarization ticket validates"
  else
    gate "Stapled notarization ticket missing or invalid"
  fi
fi

if [[ ! -f "$APPCAST_PATH" ]]; then
  fail "Appcast is missing"
else
  pass "Appcast exists"
  if xmllint --noout "$APPCAST_PATH" >/dev/null 2>&1; then
    pass "Appcast XML is well-formed"
  else
    fail "Appcast XML is not well-formed"
  fi
  appcast_title="$(sed -n 's/.*<title>\([^<]*\)<.*/\1/p' "$APPCAST_PATH" | head -n 1)"
  appcast_version="$(sed -n 's/.*<sparkle:shortVersionString>\([^<]*\)<.*/\1/p' "$APPCAST_PATH" | head -n 1)"
  appcast_build="$(sed -n 's/.*<sparkle:version>\([^<]*\)<.*/\1/p' "$APPCAST_PATH" | head -n 1)"
  appcast_pub_date="$(sed -n 's/.*<pubDate>\([^<]*\)<.*/\1/p' "$APPCAST_PATH" | head -n 1)"
  appcast_os="$(sed -n 's/.*sparkle:os="\([^"]*\)".*/\1/p' "$APPCAST_PATH" | head -n 1)"
  appcast_type="$(sed -n 's/.*type="\([^"]*\)".*/\1/p' "$APPCAST_PATH" | head -n 1)"
  appcast_length="$(sed -n 's/.*length="\([^"]*\)".*/\1/p' "$APPCAST_PATH" | head -n 1)"
  appcast_signature="$(sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p' "$APPCAST_PATH" | head -n 1)"
  zip_length=""
  if [[ -f "$ZIP_PATH" ]]; then
    zip_length="$(stat -f %z "$ZIP_PATH")"
  fi

  if [[ "$appcast_title" == "$EXPECTED_APPCAST_TITLE" ]]; then
    pass "Appcast title matches expected value ($EXPECTED_APPCAST_TITLE)"
  else
    fail "Appcast title '$appcast_title' does not match expected '$EXPECTED_APPCAST_TITLE'"
  fi

  if [[ -n "$appcast_pub_date" ]] && validate_pub_date "$appcast_pub_date"; then
    pass "Appcast pubDate is parseable"
  else
    fail "Appcast pubDate '$appcast_pub_date' is missing or invalid"
  fi

  if [[ "$appcast_os" == "$EXPECTED_APPCAST_OS" ]]; then
    pass "Appcast Sparkle OS matches expected value ($EXPECTED_APPCAST_OS)"
  else
    fail "Appcast Sparkle OS '$appcast_os' does not match expected '$EXPECTED_APPCAST_OS'"
  fi

  if [[ "$appcast_type" == "$EXPECTED_APPCAST_TYPE" ]]; then
    pass "Appcast enclosure type matches expected value ($EXPECTED_APPCAST_TYPE)"
  else
    fail "Appcast enclosure type '$appcast_type' does not match expected '$EXPECTED_APPCAST_TYPE'"
  fi

  if [[ -n "${app_version:-}" && -n "$appcast_version" && "$app_version" == "$appcast_version" ]]; then
    pass "Appcast short version matches app ($app_version)"
  else
    fail "Appcast short version '$appcast_version' does not match app '${app_version:-unknown}'"
  fi

  if [[ -n "${app_build:-}" && -n "$appcast_build" && "$app_build" == "$appcast_build" ]]; then
    pass "Appcast build version matches app ($app_build)"
  else
    fail "Appcast build version '$appcast_build' does not match app '${app_build:-unknown}'"
  fi

  if grep -q "url=\"$EXPECTED_DOWNLOAD_URL\"" "$APPCAST_PATH"; then
    pass "Appcast download URL matches expected URL"
  else
    gate "Appcast download URL does not match expected URL '$EXPECTED_DOWNLOAD_URL'"
  fi

  if [[ -n "$zip_length" && "$appcast_length" == "$zip_length" ]]; then
    pass "Appcast enclosure length matches ZIP"
  else
    gate "Appcast enclosure length is '$appcast_length' but ZIP length is '${zip_length:-missing}'"
  fi

  if [[ -n "$appcast_signature" && "$appcast_signature" != *REPLACE* ]]; then
    pass "Appcast EdDSA signature is populated"
    if sign_update_path="$(find_sign_update)"; then
      if "$sign_update_path" --account "$SPARKLE_KEYCHAIN_ACCOUNT" --verify "$ZIP_PATH" "$appcast_signature" >/dev/null 2>&1; then
        pass "Appcast EdDSA signature verifies against ZIP"
      else
        fail "Appcast EdDSA signature does not verify against ZIP"
      fi
    else
      gate "Sparkle sign_update not found, signature verification skipped"
    fi
  else
    gate "Appcast EdDSA signature is missing or placeholder"
  fi
fi

echo
echo "--- $passes passed, $failures failed, $gates gated ---"
if (( failures > 0 || gates > 0 )); then
  exit 1
fi
