#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/Chime4Breakfast.xcodeproj"
SCHEME="Chime4BreakfastApp"

xcodegen generate --spec "$ROOT_DIR/project.yml" --project "$ROOT_DIR" >/dev/null

setting() {
  local configuration="$1"
  local key="$2"

  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$configuration" \
    -showBuildSettings 2>/dev/null \
    | awk -v key="$key" '$1 == key && $2 == "=" { print substr($0, index($0, "=") + 2); exit }'
}

assert_setting() {
  local configuration="$1"
  local key="$2"
  local expected="$3"
  local actual

  actual="$(setting "$configuration" "$key")"
  if [[ "$actual" != "$expected" ]]; then
    echo "$configuration $key must be '$expected', found '$actual'." >&2
    return 1
  fi
}

assert_setting Debug PRODUCT_BUNDLE_IDENTIFIER "app.chime4breakfast.debug"
assert_setting Debug PRODUCT_NAME "Chime 4 Breakfast Dev"
assert_setting Debug INFOPLIST_KEY_CFBundleDisplayName "Chime 4 Breakfast Dev"

assert_setting Release PRODUCT_BUNDLE_IDENTIFIER "app.chime4breakfast.debug"
assert_setting Release PRODUCT_NAME "Chime 4 Breakfast Dev"
assert_setting Release INFOPLIST_KEY_CFBundleDisplayName "Chime 4 Breakfast Dev"

assert_setting Distribution PRODUCT_BUNDLE_IDENTIFIER "app.chime4breakfast"
assert_setting Distribution PRODUCT_NAME "Chime 4 Breakfast"
assert_setting Distribution INFOPLIST_KEY_CFBundleDisplayName "Chime 4 Breakfast"

echo "Build identities are isolated correctly."
