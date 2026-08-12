#!/usr/bin/env bash
# Archive, export, notarize, and package Parcel for public download.
#
# Required environment variables:
#   DEVELOPMENT_TEAM   — Apple Developer Team ID
#   APPLE_ID           — Apple ID for notarytool (optional when NOTARYTOOL_PROFILE is set)
#   APPLE_APP_PASSWORD — app-specific password (optional when NOTARYTOOL_PROFILE is set)
#   NOTARYTOOL_PROFILE — keychain profile for notarytool (optional alternative)
#
# Usage:
#   DEVELOPMENT_TEAM=XXXXXXXXXX ./Scripts/release.sh
#   SKIP_NOTARIZE=1 DEVELOPMENT_TEAM=XXXXXXXXXX ./Scripts/release.sh   # local test build
#   UPDATE_APPCAST=1 DEVELOPMENT_TEAM=XXXXXXXXXX ... ./Scripts/release.sh
#   NOTARYTOOL_PROFILE=parcel-release DEVELOPMENT_TEAM=XXXXXXXXXX ./Scripts/release.sh
#
# Optional:
#   RUN_RELEASE_PREFLIGHT=0 — skip external release-gate preflight
#   VERIFY_RELEASE=0 — skip final Website/public/downloads/Parcel.zip verification
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

if [[ -z "${RUN_RELEASE_PREFLIGHT+x}" ]]; then
  if [[ "${SKIP_NOTARIZE:-}" == "1" ]]; then
    RUN_RELEASE_PREFLIGHT=0
  else
    RUN_RELEASE_PREFLIGHT=1
  fi
fi

if [[ -z "${VERIFY_RELEASE+x}" ]]; then
  if [[ "${SKIP_NOTARIZE:-}" == "1" ]]; then
    VERIFY_RELEASE=0
  else
    VERIFY_RELEASE=1
  fi
fi

if [[ "$RUN_RELEASE_PREFLIGHT" == "1" ]]; then
  echo "==> Verifying release gates"
  "$ROOT/Scripts/verify-release-gates.sh"
else
  echo "==> Skipping release gate preflight (RUN_RELEASE_PREFLIGHT=0)"
fi

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
  CODE_SIGN_STYLE=Automatic \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO

EXPORT_OPTS="$ROOT/build/ExportOptions.plist"
sed "s/\$(DEVELOPMENT_TEAM)/$DEVELOPMENT_TEAM/g" "$ROOT/Scripts/ExportOptions.plist" > "$EXPORT_OPTS"

echo "==> Exporting Developer ID build"
rm -rf "$EXPORT_PATH"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTS"

echo "==> Verifying code signature + entitlements"
codesign --verify --deep --strict "$APP_PATH"
if codesign -d --entitlements :- "$APP_PATH" 2>/dev/null | grep -q "get-task-allow"; then
  echo "ERROR: Release app still has get-task-allow — refusing to package." >&2
  exit 1
fi
if ! codesign -d --entitlements :- "$APP_PATH" 2>/dev/null | grep -q "network.client"; then
  echo "ERROR: Release app missing network.client (Sparkle/upload will fail in sandbox)." >&2
  exit 1
fi
PUBKEY="$(/usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' "$APP_PATH/Contents/Info.plist" 2>/dev/null || true)"
if [[ -z "$PUBKEY" || "$PUBKEY" == *REPLACE_WITH* ]]; then
  echo "ERROR: SUPublicEDKey is missing or still a placeholder." >&2
  exit 1
fi
echo "    SUPublicEDKey OK ($PUBKEY)"

echo "==> Creating zip"
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

if [[ "${SKIP_NOTARIZE:-}" != "1" ]]; then
  if [[ -n "${NOTARYTOOL_PROFILE:-}" ]]; then
    echo "==> Submitting for notarization with keychain profile"
    xcrun notarytool submit "$ZIP_PATH" \
      --keychain-profile "$NOTARYTOOL_PROFILE" \
      --wait
  elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_PASSWORD:-}" ]]; then
    echo "==> Submitting for notarization with Apple ID credentials"
    xcrun notarytool submit "$ZIP_PATH" \
      --apple-id "$APPLE_ID" \
      --password "$APPLE_APP_PASSWORD" \
      --team-id "$DEVELOPMENT_TEAM" \
      --wait
  else
    echo "Set NOTARYTOOL_PROFILE or APPLE_ID and APPLE_APP_PASSWORD to notarize, or SKIP_NOTARIZE=1." >&2
    exit 1
  fi
  echo "==> Stapling ticket"
  xcrun stapler staple "$APP_PATH"
  rm -f "$ZIP_PATH"
  ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
fi

mkdir -p "$(dirname "$WEBSITE_ZIP")"
cp "$ZIP_PATH" "$WEBSITE_ZIP"

if [[ "${UPDATE_APPCAST:-}" == "1" ]]; then
  echo "==> Updating Sparkle appcast"
  "$ROOT/Scripts/update-appcast.sh" "$WEBSITE_ZIP"
fi

if [[ "$VERIFY_RELEASE" == "1" ]]; then
  echo "==> Verifying public website ZIP"
  "$ROOT/Scripts/verify-release.sh" "$WEBSITE_ZIP"
else
  echo "==> Skipping final public ZIP verification (VERIFY_RELEASE=0)"
fi

echo "==> Done: $ZIP_PATH"
echo "    Website artifact: $WEBSITE_ZIP"
echo "Next: deploy the website after final QA sign-off."
