#!/bin/zsh

# Builds a Release Chime 4 Breakfast.app and packages it into a DMG.
#
# Optional environment variables enable signing + notarization:
#   DEVELOPER_ID   "Developer ID Application: Your Name (TEAMID)"  -> codesigns the app
#   NOTARY_PROFILE name of a stored notarytool keychain profile    -> notarizes + staples
#
# Without those, it produces an unsigned DMG suitable for local testing only.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

BUILD_DIR="$ROOT_DIR/.release"
DERIVED="$BUILD_DIR/DerivedData"
APP_NAME="Chime 4 Breakfast"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Generating project"
xcodegen generate >/dev/null

echo "==> Building Release"
xcodebuild \
  -scheme Chime4BreakfastApp \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  -destination 'platform=macOS' \
  build >/dev/null

APP_PATH="$DERIVED/Build/Products/Release/$APP_NAME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Build did not produce $APP_PATH" >&2
  exit 1
fi

if [[ -n "${DEVELOPER_ID:-}" ]]; then
  echo "==> Code signing with Developer ID"
  codesign --force --deep --options runtime --timestamp \
    --sign "$DEVELOPER_ID" "$APP_PATH"
  codesign --verify --strict --verbose=2 "$APP_PATH"
else
  echo "==> Skipping code signing (set DEVELOPER_ID to enable)"
fi

echo "==> Creating DMG"
STAGE="$BUILD_DIR/dmg"
mkdir -p "$STAGE"
cp -R "$APP_PATH" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG_PATH" >/dev/null

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  echo "==> Notarizing"
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
else
  echo "==> Skipping notarization (set NOTARY_PROFILE to enable)"
fi

echo "Done: $DMG_PATH"
