#!/usr/bin/env bash
# Archive, export, notarize, and package Parcel for public download.
#
# Required environment variables:
#   DEVELOPMENT_TEAM   — Apple Developer Team ID
#   APPLE_ID           — Apple ID for notarytool (optional if skipping notarize)
#   APPLE_APP_PASSWORD — app-specific password (optional)
#
# Usage:
#   DEVELOPMENT_TEAM=XXXXXXXXXX ./Scripts/release.sh
#   SKIP_NOTARIZE=1 DEVELOPMENT_TEAM=XXXXXXXXXX ./Scripts/release.sh   # local test build
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="Parcel"
CONFIG="Release"
ARCHIVE_PATH="$ROOT/build/Parcel.xcarchive"
EXPORT_PATH="$ROOT/build/export"
APP_PATH="$EXPORT_PATH/Parcel.app"
ZIP_PATH="$ROOT/build/Parcel.zip"
WEBSITE_ZIP="$ROOT/Website/public/downloads/Parcel.zip"

if [[ -z "${DEVELOPMENT_TEAM:-}" ]]; then
  echo "Set DEVELOPMENT_TEAM to your Apple Developer Team ID." >&2
  exit 1
fi

echo "==> Generating Xcode project"
xcodegen generate

echo "==> Resolving Swift packages"
xcodebuild -resolvePackageDependencies -project Parcel.xcodeproj -scheme "$SCHEME"

echo "==> Archiving ($CONFIG)"
xcodebuild archive \
  -project Parcel.xcodeproj \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -archivePath "$ARCHIVE_PATH" \
  -destination "generic/platform=macOS" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  CODE_SIGN_STYLE=Automatic

EXPORT_OPTS="$ROOT/build/ExportOptions.plist"
sed "s/\$(DEVELOPMENT_TEAM)/$DEVELOPMENT_TEAM/g" "$ROOT/Scripts/ExportOptions.plist" > "$EXPORT_OPTS"

echo "==> Exporting Developer ID build"
rm -rf "$EXPORT_PATH"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTS"

echo "==> Verifying code signature"
codesign --verify --deep --strict "$APP_PATH"

echo "==> Creating zip"
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

if [[ "${SKIP_NOTARIZE:-}" != "1" ]]; then
  if [[ -z "${APPLE_ID:-}" || -z "${APPLE_APP_PASSWORD:-}" ]]; then
    echo "Set APPLE_ID and APPLE_APP_PASSWORD to notarize, or SKIP_NOTARIZE=1." >&2
    exit 1
  fi
  echo "==> Submitting for notarization"
  xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --team-id "$DEVELOPMENT_TEAM" \
    --wait
  echo "==> Stapling ticket"
  xcrun stapler staple "$APP_PATH"
  rm -f "$ZIP_PATH"
  ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
fi

mkdir -p "$(dirname "$WEBSITE_ZIP")"
cp "$ZIP_PATH" "$WEBSITE_ZIP"
echo "==> Done: $ZIP_PATH"
echo "    Website artifact: $WEBSITE_ZIP"
echo "Next: update Website/public/appcast.xml sparkle:edSignature and deploy."
