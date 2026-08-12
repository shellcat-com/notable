#!/usr/bin/env bash
# Dry-run real Sparkle signing against temp copies of the website ZIP and appcast.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
SPARKLE_KEYCHAIN_ACCOUNT="${SPARKLE_KEYCHAIN_ACCOUNT:-parcel.parable.dev}"
SPARKLE_SIGNING_TIMEOUT_SECONDS="${SPARKLE_SIGNING_TIMEOUT_SECONDS:-20}"

passes=0
failures=0
gates=0

pass() { echo "PASS: $*"; passes=$((passes + 1)); }
fail() { echo "FAIL: $*"; failures=$((failures + 1)); }
gate() { echo "GATE: $*"; gates=$((gates + 1)); }

finish() {
  echo
  echo "--- $passes passed, $failures failed, $gates gated ---"
  if (( failures > 0 )); then
    exit 2
  fi
  if (( gates > 0 )); then
    exit 1
  fi
}

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

run_update_appcast_with_timeout() {
  APPCAST_PATH="$appcast_path" Scripts/update-appcast.sh "$zip_path" >"$tmp_dir/update.log" 2>&1 &
  local update_pid=$!
  local elapsed=0

  while kill -0 "$update_pid" >/dev/null 2>&1; do
    if (( elapsed >= SPARKLE_SIGNING_TIMEOUT_SECONDS )); then
      local children
      children="$(pgrep -P "$update_pid" 2>/dev/null || true)"
      local child
      for child in $children; do
        pkill -TERM -P "$child" 2>/dev/null || true
        kill "$child" 2>/dev/null || true
      done
      kill "$update_pid" 2>/dev/null || true
      wait "$update_pid" 2>/dev/null || true
      return 124
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done

  wait "$update_pid"
}

zip_source="$ROOT/Website/public/downloads/Parcel.zip"
appcast_source="$ROOT/Website/public/appcast.xml"

if [[ ! -f "$zip_source" ]]; then
  fail "Website ZIP is missing: $zip_source"
  finish
fi
if [[ ! -f "$appcast_source" ]]; then
  fail "Appcast is missing: $appcast_source"
  finish
fi
pass "Website ZIP and appcast exist"

sign_update_path="$(find_sign_update || true)"
if [[ -z "$sign_update_path" ]]; then
  gate "Sparkle sign_update is unavailable"
  finish
fi
pass "Sparkle sign_update available at $sign_update_path"

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/parcel-real-sparkle-test.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

zip_path="$tmp_dir/Parcel.zip"
appcast_path="$tmp_dir/appcast.xml"
cp "$zip_source" "$zip_path"
cp "$appcast_source" "$appcast_path"
original_hash="$(shasum -a 256 "$appcast_source" | awk '{print $1}')"

metadata_dir="$tmp_dir/metadata"
mkdir -p "$metadata_dir"
if ditto -x -k "$zip_path" "$metadata_dir"; then
  metadata_app_path="$(find "$metadata_dir" -maxdepth 1 -name '*.app' -print -quit)"
  if [[ -n "$metadata_app_path" ]]; then
    expected_short_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$metadata_app_path/Contents/Info.plist" 2>/dev/null || true)"
    expected_build_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$metadata_app_path/Contents/Info.plist" 2>/dev/null || true)"
  else
    expected_short_version=""
    expected_build_version=""
  fi
else
  expected_short_version=""
  expected_build_version=""
fi

if [[ -n "$expected_short_version" && -n "$expected_build_version" ]]; then
  pass "Website ZIP app metadata is readable"
else
  fail "Website ZIP app metadata is not readable"
  finish
fi

if run_update_appcast_with_timeout; then
  pass "Real Sparkle signer updated temp appcast"
else
  signing_status=$?
  if [[ "$signing_status" == "124" ]]; then
    gate "Real Sparkle signing timed out waiting for Keychain access; approve the prompt or use SPARKLE_ED_PRIVATE_KEY/SPARKLE_ED_KEY_FILE"
  else
    gate "Real Sparkle signing did not complete; import the EdDSA private key or set SPARKLE_ED_PRIVATE_KEY/SPARKLE_ED_KEY_FILE"
  fi
  sed 's/^/    /' "$tmp_dir/update.log" || true
  finish
fi

expected_length="$(stat -f %z "$zip_path")"
actual_length="$(sed -n 's/.*length="\([^"]*\)".*/\1/p' "$appcast_path" | head -n 1)"
actual_signature="$(sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p' "$appcast_path" | head -n 1)"
actual_short_version="$(sed -n 's/.*<sparkle:shortVersionString>\([^<]*\)<.*/\1/p' "$appcast_path" | head -n 1)"
actual_build_version="$(sed -n 's/.*<sparkle:version>\([^<]*\)<.*/\1/p' "$appcast_path" | head -n 1)"
actual_title="$(sed -n 's/.*<title>\([^<]*\)<.*/\1/p' "$appcast_path" | sed -n '2p')"
actual_pub_date="$(sed -n 's/.*<pubDate>\([^<]*\)<.*/\1/p' "$appcast_path" | head -n 1)"
current_hash="$(shasum -a 256 "$appcast_source" | awk '{print $1}')"

if [[ "$actual_short_version" == "$expected_short_version" ]]; then
  pass "Temp appcast short version matches ZIP app"
else
  fail "Temp appcast short version '$actual_short_version' did not match '$expected_short_version'"
fi

if [[ "$actual_build_version" == "$expected_build_version" ]]; then
  pass "Temp appcast build version matches ZIP app"
else
  fail "Temp appcast build version '$actual_build_version' did not match '$expected_build_version'"
fi

if [[ "$actual_title" == "$expected_short_version" ]]; then
  pass "Temp appcast item title matches ZIP app short version"
else
  fail "Temp appcast item title '$actual_title' did not match '$expected_short_version'"
fi

if date -j -f "%a, %d %b %Y %H:%M:%S %z" "$actual_pub_date" >/dev/null 2>&1; then
  pass "Temp appcast pubDate is parseable"
else
  fail "Temp appcast pubDate is not parseable: '$actual_pub_date'"
fi

if [[ "$actual_length" == "$expected_length" ]]; then
  pass "Temp appcast length matches ZIP"
else
  fail "Temp appcast length '$actual_length' did not match '$expected_length'"
fi

if [[ -n "$actual_signature" && "$actual_signature" != *REPLACE* ]]; then
  pass "Temp appcast EdDSA signature is populated"
  if "$sign_update_path" --account "$SPARKLE_KEYCHAIN_ACCOUNT" --verify "$zip_path" "$actual_signature" >/dev/null 2>&1; then
    pass "Temp appcast EdDSA signature verifies against ZIP"
  else
    fail "Temp appcast EdDSA signature does not verify against ZIP"
  fi
else
  fail "Temp appcast EdDSA signature is missing or placeholder"
fi

if [[ "$current_hash" == "$original_hash" ]]; then
  pass "Real Website/public/appcast.xml unchanged"
else
  fail "Real Website/public/appcast.xml changed during real-signing dry-run"
fi

finish
