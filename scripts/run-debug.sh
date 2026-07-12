#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_PATH="$ROOT_DIR/.derived-data"

cd "$ROOT_DIR"

xcodegen generate >/dev/null
xcodebuild -project Chime4Breakfast.xcodeproj -scheme Chime4BreakfastApp -derivedDataPath "$DERIVED_DATA_PATH" -destination 'platform=macOS' build >/dev/null

APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug/Chime 4 Breakfast.app"
INSTALL_PATH="$HOME/Applications/Chime 4 Breakfast.app"
SIGNING_IDENTITY="${CHIME_DEBUG_SIGNING_IDENTITY:-}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Unable to locate built app bundle."
  exit 1
fi

if pgrep -x Chime4BreakfastApp >/dev/null; then
  pkill -x Chime4BreakfastApp
  sleep 1
fi

mkdir -p "$HOME/Applications"
rm -rf "$INSTALL_PATH"
ditto "$APP_PATH" "$INSTALL_PATH"

if [[ -z "$SIGNING_IDENTITY" ]]; then
  SIGNING_IDENTITY="$(
    security find-identity -v -p codesigning 2>/dev/null \
      | sed -n 's/.*"\(Developer ID Application: [^"]*\)".*/\1/p' \
      | head -n 1
  )"
fi

if [[ -z "$SIGNING_IDENTITY" ]]; then
  SIGNING_IDENTITY="$(
    security find-identity -v -p codesigning 2>/dev/null \
      | sed -n 's/.*"\(Apple Development: [^"]*\)".*/\1/p' \
      | head -n 1
  )"
fi

if [[ -n "$SIGNING_IDENTITY" ]]; then
  codesign --force --deep --options runtime --timestamp=none --sign "$SIGNING_IDENTITY" "$INSTALL_PATH" >/dev/null
  codesign --verify --strict --verbose=2 "$INSTALL_PATH" >/dev/null
  echo "Signed with: $SIGNING_IDENTITY"
else
  echo "Warning: no Developer ID or Apple Development identity found; app remains ad-hoc signed." >&2
  echo "Accessibility permission may reset on every rebuild." >&2
fi

open -g "$INSTALL_PATH"
echo "Launched: $INSTALL_PATH"
