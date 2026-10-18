#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${1:-Debug}"
DERIVED="${SLATE_DERIVED_DATA:-$ROOT/DerivedData}"

if [ "${SKIP_LAYER_CHECK:-0}" != "1" ]; then
    "$ROOT/Scripts/check-layers.sh"
fi

xcodebuild \
    -project "$ROOT/Slate.xcodeproj" \
    -scheme Slate \
    -configuration "$CONFIG" \
    -destination 'platform=macOS,arch=arm64' \
    -derivedDataPath "$DERIVED" \
    -quiet \
    build

echo "$DERIVED/Build/Products/$CONFIG/Slate.app"
