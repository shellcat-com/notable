#!/usr/bin/env bash
# Verify Parcel's embedded Sparkle public key matches the configured signing account.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SPARKLE_KEYCHAIN_ACCOUNT="${SPARKLE_KEYCHAIN_ACCOUNT:-parcel.parable.dev}"
SPARKLE_KEY_TIMEOUT_SECONDS="${SPARKLE_KEY_TIMEOUT_SECONDS:-10}"
SOURCE_PLIST="$ROOT/Sources/Parcel/Resources/Info.plist"
WEBSITE_ZIP="${WEBSITE_ZIP:-$ROOT/Website/public/downloads/Parcel.zip}"

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

find_generate_keys() {
  if [[ -n "${SPARKLE_GENERATE_KEYS:-}" && -x "$SPARKLE_GENERATE_KEYS" ]]; then
    echo "$SPARKLE_GENERATE_KEYS"
    return 0
  fi
  if command -v generate_keys >/dev/null 2>&1; then
    command -v generate_keys
    return 0
  fi
  local candidates=(
    "$ROOT/.derivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys"
    "$ROOT/.derivedData-release/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys"
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

run_generate_keys_with_timeout() {
  local output_file="$1"
  "$generate_keys_path" --account "$SPARKLE_KEYCHAIN_ACCOUNT" -p >"$output_file" 2>&1 &
  local key_pid=$!
  local elapsed=0

  while kill -0 "$key_pid" >/dev/null 2>&1; do
    if (( elapsed >= SPARKLE_KEY_TIMEOUT_SECONDS )); then
      pkill -TERM -P "$key_pid" 2>/dev/null || true
      kill "$key_pid" 2>/dev/null || true
      wait "$key_pid" 2>/dev/null || true
      return 124
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done

  wait "$key_pid"
}

plist_key() {
  /usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' "$1" 2>/dev/null || true
}

if [[ ! -f "$SOURCE_PLIST" ]]; then
  fail "Source Info.plist is missing"
  finish
fi

source_key="$(plist_key "$SOURCE_PLIST")"
if [[ -n "$source_key" && "$source_key" != *REPLACE* ]]; then
  pass "Source SUPublicEDKey is populated"
else
  fail "Source SUPublicEDKey is missing or placeholder"
fi

generate_keys_path="$(find_generate_keys || true)"
if [[ -z "$generate_keys_path" ]]; then
  gate "Sparkle generate_keys is unavailable; resolve packages or set SPARKLE_GENERATE_KEYS"
else
  pass "Sparkle generate_keys available at $generate_keys_path"
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/parcel-sparkle-key.XXXXXX")"
  trap 'rm -rf "$tmp_dir"' EXIT
  key_output="$tmp_dir/generate_keys.log"

  if run_generate_keys_with_timeout "$key_output"; then
    keychain_key="$(tail -n 1 "$key_output" | tr -d '[:space:]')"
    if [[ -n "$keychain_key" && "$keychain_key" != *REPLACE* ]]; then
      pass "Keychain Sparkle public key is readable for account '$SPARKLE_KEYCHAIN_ACCOUNT'"
      if [[ -n "$source_key" && "$source_key" == "$keychain_key" ]]; then
        pass "Source SUPublicEDKey matches Sparkle Keychain account"
      else
        fail "Source SUPublicEDKey does not match Sparkle Keychain account"
      fi
    else
      gate "Sparkle Keychain public key output was empty"
      sed 's/^/    /' "$key_output" || true
    fi
  else
    key_status=$?
    if [[ "$key_status" == "124" ]]; then
      gate "Reading Sparkle public key timed out waiting for Keychain access"
    else
      gate "Could not read Sparkle public key for account '$SPARKLE_KEYCHAIN_ACCOUNT'"
    fi
    sed 's/^/    /' "$key_output" || true
  fi
fi

if [[ -f "$WEBSITE_ZIP" ]]; then
  zip_tmp="$(mktemp -d "${TMPDIR:-/tmp}/parcel-sparkle-zip.XXXXXX")"
  trap 'rm -rf "$zip_tmp" ${tmp_dir:-}' EXIT
  if ditto -x -k "$WEBSITE_ZIP" "$zip_tmp" >/dev/null 2>&1; then
    zip_app="$(find "$zip_tmp" -maxdepth 1 -name '*.app' -print -quit)"
    if [[ -n "$zip_app" && -f "$zip_app/Contents/Info.plist" ]]; then
      zip_key="$(plist_key "$zip_app/Contents/Info.plist")"
      if [[ -n "$source_key" && "$zip_key" == "$source_key" ]]; then
        pass "Website ZIP app SUPublicEDKey matches source"
      else
        fail "Website ZIP app SUPublicEDKey does not match source"
      fi
    else
      fail "Website ZIP does not contain a top-level app with Info.plist"
    fi
  else
    fail "Website ZIP could not be extracted"
  fi
else
  gate "Website ZIP is missing; ZIP key comparison skipped"
fi

finish
