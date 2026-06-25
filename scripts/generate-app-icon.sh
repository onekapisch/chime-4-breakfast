#!/bin/zsh

# Regenerates the AppIcon asset catalog from the Core Graphics renderer.
# Run from anywhere: ./scripts/generate-app-icon.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ICONSET="$ROOT_DIR/Sources/Chime4BreakfastApp/Resources/Assets.xcassets/AppIcon.appiconset"
TMP_DIR="$(mktemp -d)"
MASTER="$TMP_DIR/icon-1024.png"

swift "$ROOT_DIR/scripts/generate-app-icon.swift" "$MASTER"

mkdir -p "$ICONSET"

emit() {
  local name="$1"
  local px="$2"
  sips -z "$px" "$px" "$MASTER" --out "$ICONSET/$name" >/dev/null
}

emit "icon_16x16.png" 16
emit "icon_16x16@2x.png" 32
emit "icon_32x32.png" 32
emit "icon_32x32@2x.png" 64
emit "icon_128x128.png" 128
emit "icon_128x128@2x.png" 256
emit "icon_256x256.png" 256
emit "icon_256x256@2x.png" 512
emit "icon_512x512.png" 512
cp "$MASTER" "$ICONSET/icon_512x512@2x.png"

cat > "$ICONSET/Contents.json" <<'JSON'
{
  "images" : [
    { "idiom" : "mac", "scale" : "1x", "size" : "16x16", "filename" : "icon_16x16.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "16x16", "filename" : "icon_16x16@2x.png" },
    { "idiom" : "mac", "scale" : "1x", "size" : "32x32", "filename" : "icon_32x32.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "32x32", "filename" : "icon_32x32@2x.png" },
    { "idiom" : "mac", "scale" : "1x", "size" : "128x128", "filename" : "icon_128x128.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "128x128", "filename" : "icon_128x128@2x.png" },
    { "idiom" : "mac", "scale" : "1x", "size" : "256x256", "filename" : "icon_256x256.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "256x256", "filename" : "icon_256x256@2x.png" },
    { "idiom" : "mac", "scale" : "1x", "size" : "512x512", "filename" : "icon_512x512.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "512x512", "filename" : "icon_512x512@2x.png" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON

echo "Generated AppIcon at $ICONSET"
