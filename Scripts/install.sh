#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$("$ROOT/Scripts/build.sh" Release | tail -1)"
TARGET="/Applications/Slate.app"
BIN="$HOME/.local/bin"

pkill -x Slate || true
rm -rf "$TARGET"
cp -R "$APP" "$TARGET"

swift build --package-path "$ROOT/Packages/SlateKit" -c release --product slate -q
mkdir -p "$BIN"
cp "$ROOT/Packages/SlateKit/.build/release/slate" "$BIN/slate"

/System/Library/CoreServices/pbs -update || true
open "$TARGET"
echo "Installed $TARGET and $BIN/slate"
echo "To let Claude Code use your notes, run: claude mcp add slate -- slate mcp"
echo "If Claude Code cannot find slate, use the full path: claude mcp add slate -- $BIN/slate mcp"
