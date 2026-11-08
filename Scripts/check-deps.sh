#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/Packages/SlateKit/Package.swift"
PACKAGE_PINS="$ROOT/Packages/SlateKit/Package.resolved"
XCODE_PINS="$ROOT/Slate.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"

loose=$(grep -E '\.package\(url:' "$MANIFEST" | grep -v 'exact: "' || true)
if [ -n "$loose" ]; then
    echo "deps: every package needs an exact version (exact: \"x.y.z\"):"
    echo "$loose"
    exit 1
fi

pins() {
    grep -E '"(identity|revision|version)"' "$1"
}

if ! diff <(pins "$PACKAGE_PINS") <(pins "$XCODE_PINS") >/dev/null; then
    echo "deps: Packages/SlateKit/Package.resolved and the Xcode Package.resolved pin different versions"
    diff <(pins "$PACKAGE_PINS") <(pins "$XCODE_PINS") || true
    exit 1
fi

VENDORED="$ROOT/Packages/SlateKit/Vendored.lock"
while read -r name version hash file url; do
    [ -z "$name" ] && continue
    actual=$(shasum -a 256 "$ROOT/Packages/SlateKit/$file" 2>/dev/null | cut -d' ' -f1 || true)
    if [ "$actual" != "$hash" ]; then
        echo "deps: $file is not $name $version from Vendored.lock"
        exit 1
    fi
done < "$VENDORED"

echo "deps: ok"
