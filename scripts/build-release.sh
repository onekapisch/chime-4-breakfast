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

if [[ -n "${NOTARY_PROFILE:-}" && -z "${DEVELOPER_ID:-}" ]]; then
  echo "NOTARY_PROFILE requires DEVELOPER_ID so the app is signed before notarization." >&2
  exit 1
fi

BUILD_DIR="$ROOT_DIR/.release"
DERIVED="$BUILD_DIR/DerivedData"
APP_NAME="Chime 4 Breakfast"
DMG_FILENAME="Chime-4-Breakfast.dmg"
DMG_PATH="$BUILD_DIR/$DMG_FILENAME"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Generating project"
xcodegen generate >/dev/null

echo "==> Building Release"
xcodebuild \
  -project Chime4Breakfast.xcodeproj \
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
  xcrun stapler validate "$DMG_PATH"

  VERIFY_MOUNT="$(mktemp -d "${TMPDIR:-/tmp}/chime4breakfast-release.XXXXXX")"
  cleanup_verification_mount() {
    hdiutil detach "$VERIFY_MOUNT" >/dev/null 2>&1 || true
    rmdir "$VERIFY_MOUNT" >/dev/null 2>&1 || true
  }
  trap cleanup_verification_mount EXIT

  echo "==> Verifying Gatekeeper acceptance"
  hdiutil attach -readonly -nobrowse -mountpoint "$VERIFY_MOUNT" "$DMG_PATH" >/dev/null
  spctl --assess --type execute --verbose=4 "$VERIFY_MOUNT/$APP_NAME.app"
  cleanup_verification_mount
  trap - EXIT
else
  echo "==> Skipping notarization (set NOTARY_PROFILE to enable)"
fi

CHECKSUM_PATH="$BUILD_DIR/$DMG_FILENAME.sha256"
(
  cd "$BUILD_DIR"
  shasum -a 256 "$DMG_FILENAME" > "$DMG_FILENAME.sha256"
)

echo "Done: $DMG_PATH"
echo "SHA-256: $CHECKSUM_PATH"
