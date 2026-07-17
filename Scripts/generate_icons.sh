#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$ROOT/Scripts/parcel-icon-1024.png}"
ICONSET="$ROOT/Sources/Parcel/Resources/Assets.xcassets/AppIcon.appiconset"
MENUBAR="$ROOT/Sources/Parcel/Resources/Assets.xcassets/MenuBarIcon.imageset"

if [[ ! -f "$SRC" ]]; then
  echo "Source icon not found: $SRC" >&2
  exit 1
fi

mkdir -p "$ICONSET" "$MENUBAR"

gen() {
  local px="$1" out="$2"
  sips -z "$px" "$px" "$SRC" --out "$out" >/dev/null
}

gen 16  "$ICONSET/icon_16x16.png"
gen 32  "$ICONSET/icon_16x16@2x.png"
gen 32  "$ICONSET/icon_32x32.png"
gen 64  "$ICONSET/icon_32x32@2x.png"
gen 128 "$ICONSET/icon_128x128.png"
gen 256 "$ICONSET/icon_128x128@2x.png"
gen 256 "$ICONSET/icon_256x256.png"
gen 512 "$ICONSET/icon_512x512.png"
gen 512 "$ICONSET/icon_256x256@2x.png"
gen 512 "$ICONSET/icon_512x512.png"
gen 1024 "$ICONSET/icon_512x512@2x.png"
gen 36 "$MENUBAR/MenuBarIcon@2x.png"
gen 18 "$MENUBAR/MenuBarIcon.png"

cat > "$ICONSET/Contents.json" <<'JSON'
{
  "images" : [
    { "filename" : "icon_16x16.png", "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "icon_16x16@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "icon_32x32.png", "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "icon_32x32@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "icon_128x128.png", "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "icon_128x128@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "icon_256x256.png", "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "icon_256x256@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "icon_512x512.png", "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "icon_512x512@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON

cat > "$MENUBAR/Contents.json" <<'JSON'
{
  "images" : [
    { "filename" : "MenuBarIcon.png", "idiom" : "mac", "scale" : "1x" },
    { "filename" : "MenuBarIcon@2x.png", "idiom" : "mac", "scale" : "2x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 },
  "properties" : { "template-rendering-intent" : "template" }
}
JSON

echo "Generated AppIcon and MenuBarIcon assets."
