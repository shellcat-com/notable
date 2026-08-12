#!/usr/bin/env bash
# Dry-run the appcast updater with a fake Sparkle signer against temporary files.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/parcel-appcast-test.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

zip_path="$tmp_dir/Parcel.zip"
appcast_path="$tmp_dir/appcast.xml"
sign_update_path="$tmp_dir/sign_update"
original_hash="$(shasum -a 256 Website/public/appcast.xml | awk '{print $1}')"

app_bundle="$tmp_dir/Parcel.app"
mkdir -p "$app_bundle/Contents/MacOS"
cat >"$app_bundle/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>Parcel</string>
  <key>CFBundleIdentifier</key>
  <string>dev.parable.Parcel</string>
  <key>CFBundleName</key>
  <string>Parcel</string>
  <key>CFBundleDisplayName</key>
  <string>Parcel</string>
  <key>CFBundleShortVersionString</key>
  <string>9.8.7</string>
  <key>CFBundleVersion</key>
  <string>654</string>
</dict>
</plist>
PLIST
printf '#!/usr/bin/env bash\n' >"$app_bundle/Contents/MacOS/Parcel"
chmod +x "$app_bundle/Contents/MacOS/Parcel"
ditto -c -k --keepParent "$app_bundle" "$zip_path"
cp Website/public/appcast.xml "$appcast_path"

cat >"$sign_update_path" <<'FAKE_SIGN_UPDATE'
#!/usr/bin/env bash
set -euo pipefail
zip="${@: -1}"
length="$(stat -f %z "$zip")"
echo "sparkle:edSignature=\"FAKE_SIGNATURE_FOR_APPCAST_TEST\" length=\"$length\""
FAKE_SIGN_UPDATE
chmod +x "$sign_update_path"

APPCAST_PATH="$appcast_path" SPARKLE_SIGN_UPDATE="$sign_update_path" Scripts/update-appcast.sh "$zip_path" >"$tmp_dir/update.log"

expected_length="$(stat -f %z "$zip_path")"
actual_length="$(sed -n 's/.*length="\([^"]*\)".*/\1/p' "$appcast_path" | head -n 1)"
actual_signature="$(sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p' "$appcast_path" | head -n 1)"
actual_short_version="$(sed -n 's/.*<sparkle:shortVersionString>\([^<]*\)<.*/\1/p' "$appcast_path" | head -n 1)"
actual_build_version="$(sed -n 's/.*<sparkle:version>\([^<]*\)<.*/\1/p' "$appcast_path" | head -n 1)"
actual_title="$(sed -n 's/.*<title>\([^<]*\)<.*/\1/p' "$appcast_path" | sed -n '2p')"
actual_pub_date="$(sed -n 's/.*<pubDate>\([^<]*\)<.*/\1/p' "$appcast_path" | head -n 1)"
current_hash="$(shasum -a 256 Website/public/appcast.xml | awk '{print $1}')"

if [[ "$actual_length" != "$expected_length" ]]; then
  echo "FAIL: appcast length '$actual_length' did not match '$expected_length'" >&2
  exit 1
fi
if [[ "$actual_short_version" != "9.8.7" ]]; then
  echo "FAIL: appcast short version was '$actual_short_version'" >&2
  exit 1
fi
if [[ "$actual_build_version" != "654" ]]; then
  echo "FAIL: appcast build version was '$actual_build_version'" >&2
  exit 1
fi
if [[ "$actual_title" != "9.8.7" ]]; then
  echo "FAIL: appcast item title was '$actual_title'" >&2
  exit 1
fi
if ! date -j -f "%a, %d %b %Y %H:%M:%S %z" "$actual_pub_date" >/dev/null 2>&1; then
  echo "FAIL: appcast pubDate was not parseable: '$actual_pub_date'" >&2
  exit 1
fi
if [[ "$actual_signature" != "FAKE_SIGNATURE_FOR_APPCAST_TEST" ]]; then
  echo "FAIL: appcast signature was '$actual_signature'" >&2
  exit 1
fi
if [[ "$current_hash" != "$original_hash" ]]; then
  echo "FAIL: Website/public/appcast.xml changed during dry-run" >&2
  exit 1
fi

bad_appcast_path="$tmp_dir/bad-appcast.xml"
printf '<rss><channel><item><title>Broken</title>\n' >"$bad_appcast_path"
bad_before_hash="$(shasum -a 256 "$bad_appcast_path" | awk '{print $1}')"
if APPCAST_PATH="$bad_appcast_path" SPARKLE_SIGN_UPDATE="$sign_update_path" Scripts/update-appcast.sh "$zip_path" >"$tmp_dir/bad-update.log" 2>&1; then
  echo "FAIL: malformed appcast update unexpectedly succeeded" >&2
  exit 1
fi
bad_after_hash="$(shasum -a 256 "$bad_appcast_path" | awk '{print $1}')"
if [[ "$bad_after_hash" != "$bad_before_hash" ]]; then
  echo "FAIL: malformed appcast source changed during failed update" >&2
  exit 1
fi

echo "PASS: appcast updater writes app version/build/title/pubDate, ZIP length, and signature in a temp appcast"
echo "PASS: malformed appcast is rejected without modifying source"
echo "PASS: real Website/public/appcast.xml unchanged"
