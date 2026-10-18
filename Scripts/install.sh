#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$(SLATE_DERIVED_DATA="$ROOT/DerivedData/Install" "$ROOT/Scripts/build.sh" Release | tail -1)"
TARGET="/Applications/Slate.app"
BIN="$HOME/.local/bin"

swift build --package-path "$ROOT/Packages/SlateKit" --scratch-path "$ROOT/DerivedData/InstallCLI" -c release --product slate -q
mkdir -p "$BIN"
cp "$ROOT/DerivedData/InstallCLI/release/slate" "$BIN/slate"

"$ROOT/Scripts/quit.sh"
rm -rf "$TARGET"
cp -R "$APP" "$TARGET"

/System/Library/CoreServices/pbs -update || true
open "$TARGET"
echo "Installed $TARGET and $BIN/slate"
echo "To let Claude Code use your notes, run: claude mcp add -s user slate -- slate mcp"
echo "If Claude Code cannot find slate, use the full path: claude mcp add -s user slate -- $BIN/slate mcp"
