#!/usr/bin/env bash
# Update Website/public/appcast.xml with the final app metadata, ZIP length, and Sparkle EdDSA signature.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ZIP_PATH="${1:-$ROOT/Website/public/downloads/Parcel.zip}"
APPCAST_PATH="${APPCAST_PATH:-$ROOT/Website/public/appcast.xml}"
SPARKLE_KEYCHAIN_ACCOUNT="${SPARKLE_KEYCHAIN_ACCOUNT:-parcel.parable.dev}"

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

file_size() {
  if stat -f %z "$1" >/dev/null 2>&1; then
    stat -f %z "$1"
  else
    stat -c %s "$1"
  fi
}

rfc_822_utc_now() {
  LC_ALL=C TZ=UTC date -u "+%a, %d %b %Y %H:%M:%S +0000"
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

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "ERROR: ZIP not found: $ZIP_PATH" >&2
  exit 1
fi
if [[ ! -f "$APPCAST_PATH" ]]; then
  echo "ERROR: appcast not found: $APPCAST_PATH" >&2
  exit 1
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/parcel-appcast-update.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

if ! ditto -x -k "$ZIP_PATH" "$tmp_dir"; then
  echo "ERROR: ZIP does not extract with ditto: $ZIP_PATH" >&2
  exit 1
fi

app_path="$(find "$tmp_dir" -maxdepth 1 -name '*.app' -print -quit)"
if [[ -z "$app_path" || ! -d "$app_path" ]]; then
  echo "ERROR: ZIP does not contain a top-level app bundle: $ZIP_PATH" >&2
  exit 1
fi

info_plist="$app_path/Contents/Info.plist"
if [[ ! -f "$info_plist" ]]; then
  echo "ERROR: app bundle is missing Info.plist: $app_path" >&2
  exit 1
fi

short_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$info_plist" 2>/dev/null || true)"
build_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$info_plist" 2>/dev/null || true)"
if [[ -z "$short_version" || -z "$build_version" ]]; then
  echo "ERROR: app Info.plist is missing CFBundleShortVersionString or CFBundleVersion" >&2
  exit 1
fi

SIGN_UPDATE="$(find_sign_update || true)"
if [[ -z "$SIGN_UPDATE" ]]; then
  echo "ERROR: Sparkle sign_update not found. Set SPARKLE_SIGN_UPDATE=/path/to/sign_update." >&2
  exit 1
fi

if [[ -n "${SPARKLE_ED_PRIVATE_KEY:-}" ]]; then
  signature_output="$(printf '%s' "$SPARKLE_ED_PRIVATE_KEY" | "$SIGN_UPDATE" --ed-key-file - "$ZIP_PATH")"
elif [[ -n "${SPARKLE_ED_KEY_FILE:-}" ]]; then
  signature_output="$("$SIGN_UPDATE" --ed-key-file "$SPARKLE_ED_KEY_FILE" "$ZIP_PATH")"
else
  signature_output="$("$SIGN_UPDATE" --account "$SPARKLE_KEYCHAIN_ACCOUNT" "$ZIP_PATH")"
fi

length="$(echo "$signature_output" | sed -n 's/.*length="\([^"]*\)".*/\1/p' | head -n 1)"
signature="$(echo "$signature_output" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p' | head -n 1)"
actual_length="$(file_size "$ZIP_PATH")"
pub_date="$(rfc_822_utc_now)"

if [[ -z "$length" || -z "$signature" ]]; then
  echo "ERROR: could not parse sign_update output:" >&2
  echo "$signature_output" >&2
  exit 1
fi
if [[ "$length" != "$actual_length" ]]; then
  echo "ERROR: sign_update length '$length' does not match ZIP length '$actual_length'" >&2
  exit 1
fi

updated_appcast="$tmp_dir/appcast.updated.xml"
cp "$APPCAST_PATH" "$updated_appcast"

SHORT_VERSION="$short_version" BUILD_VERSION="$build_version" PUB_DATE="$pub_date" LENGTH="$length" SIGNATURE="$signature" perl -0pi -e '
  s{(<item>\s*<title>)[^<]*(</title>)}{$1$ENV{SHORT_VERSION}$2}s;
  s{(<sparkle:version>)[^<]*(</sparkle:version>)}{$1$ENV{BUILD_VERSION}$2}s;
  s{(<sparkle:shortVersionString>)[^<]*(</sparkle:shortVersionString>)}{$1$ENV{SHORT_VERSION}$2}s;
  s{(<pubDate>)[^<]*(</pubDate>)}{$1$ENV{PUB_DATE}$2}s;
  s/length="[^"]*"/length="$ENV{LENGTH}"/s;
  s/sparkle:edSignature="[^"]*"/sparkle:edSignature="$ENV{SIGNATURE}"/s;
' "$updated_appcast"

if ! command -v xmllint >/dev/null 2>&1; then
  echo "ERROR: xmllint not found; cannot validate updated appcast XML." >&2
  exit 1
fi
if ! xmllint --noout "$updated_appcast" >/dev/null 2>&1; then
  echo "ERROR: updated appcast XML is not well-formed; original appcast was left unchanged." >&2
  exit 1
fi

updated_title="$(sed -n 's/.*<title>\([^<]*\)<.*/\1/p' "$updated_appcast" | sed -n '2p')"
updated_build_version="$(sed -n 's/.*<sparkle:version>\([^<]*\)<.*/\1/p' "$updated_appcast" | head -n 1)"
updated_short_version="$(sed -n 's/.*<sparkle:shortVersionString>\([^<]*\)<.*/\1/p' "$updated_appcast" | head -n 1)"
updated_pub_date="$(sed -n 's/.*<pubDate>\([^<]*\)<.*/\1/p' "$updated_appcast" | head -n 1)"
updated_length="$(sed -n 's/.*length="\([^"]*\)".*/\1/p' "$updated_appcast" | head -n 1)"
updated_signature="$(sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p' "$updated_appcast" | head -n 1)"

if [[ "$updated_title" != "$short_version" ]]; then
  echo "ERROR: updated item title '$updated_title' does not match app short version '$short_version'" >&2
  exit 1
fi
if [[ "$updated_short_version" != "$short_version" ]]; then
  echo "ERROR: updated short version '$updated_short_version' does not match app short version '$short_version'" >&2
  exit 1
fi
if [[ "$updated_build_version" != "$build_version" ]]; then
  echo "ERROR: updated build version '$updated_build_version' does not match app build '$build_version'" >&2
  exit 1
fi
if [[ "$updated_length" != "$length" ]]; then
  echo "ERROR: updated length '$updated_length' does not match signer length '$length'" >&2
  exit 1
fi
if [[ "$updated_signature" != "$signature" ]]; then
  echo "ERROR: updated signature does not match signer output" >&2
  exit 1
fi
if ! validate_pub_date "$updated_pub_date"; then
  echo "ERROR: updated pubDate '$updated_pub_date' is not parseable" >&2
  exit 1
fi

mv "$updated_appcast" "$APPCAST_PATH"

echo "Updated $APPCAST_PATH"
echo "  sparkle:shortVersionString=$short_version"
echo "  sparkle:version=$build_version"
echo "  pubDate=$pub_date"
echo "  length=$length"
echo "  sparkle:edSignature=$signature"
