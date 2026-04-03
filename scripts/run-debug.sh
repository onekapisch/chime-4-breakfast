#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_PATH="$ROOT_DIR/.derived-data"

cd "$ROOT_DIR"

xcodegen generate >/dev/null
xcodebuild -scheme HornOKPleaseApp -derivedDataPath "$DERIVED_DATA_PATH" -destination 'platform=macOS,arch=arm64' build >/dev/null

APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug/Horn OK Please.app"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Unable to locate built app bundle."
  exit 1
fi

open -g "$APP_PATH"
echo "Launched: $APP_PATH"
