#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT_DIR"

xcodegen generate >/dev/null
xcodebuild -scheme HornOKPleaseApp -destination 'platform=macOS,arch=arm64' build >/dev/null

APP_PATH="$(find "$HOME/Library/Developer/Xcode/DerivedData" -path '*Horn OK Please.app' -type d | head -n 1)"

if [[ -z "$APP_PATH" ]]; then
  echo "Unable to locate built app bundle."
  exit 1
fi

open -g "$APP_PATH"
echo "Launched: $APP_PATH"
