#!/bin/zsh

# Rasterizes the README brand SVGs to PNG using macOS QuickLook (qlmanage),
# then center-crops away the square QuickLook padding.
# Run from anywhere: ./scripts/render-readme-assets.sh

set -euo pipefail

DIR="$(cd "$(dirname "$0")/../.github/assets" && pwd)"
cd "$DIR"

render() { # $1 = base name, $2 = content height
  qlmanage -t -s 1600 -o . "$1.svg" >/dev/null 2>&1
  sips -c "$2" 1600 "$1.svg.png" --out "$1.png" >/dev/null
  rm -f "$1.svg.png"
}

render hero 860
render glow-demo 900

# popover.svg is authored as a square canvas; crop only the side margins
qlmanage -t -s 1240 -o . popover.svg >/dev/null 2>&1
sips -c 1240 1040 popover.svg.png --out popover.png >/dev/null
rm -f popover.svg.png

echo "Rendered hero.png + glow-demo.png + popover.png in $DIR"
