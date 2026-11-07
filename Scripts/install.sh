#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SUPPORT="$HOME/Library/Application Support/Slate"
SOURCE="$SUPPORT/source"
UPDATE_DIR="$SUPPORT/update"
BRANCH="${SLATE_UPDATE_BRANCH:-main}"
source "$ROOT/Scripts/update-status.sh"

update_status building
APP="$(SLATE_DERIVED_DATA="$ROOT/DerivedData/Install" "$ROOT/Scripts/build.sh" Release | tail -1)"
TARGET="/Applications/Slate.app"
BIN="$HOME/.local/bin"
IDENTITY="${SLATE_SIGN_IDENTITY:-}"
IDENTITY_FILE="$HOME/.config/slate/sign-identity"
if [[ -z "$IDENTITY" && -f "$IDENTITY_FILE" ]]; then
  IDENTITY="$(tr -d '[:space:]' < "$IDENTITY_FILE")"
fi

sign() {
  [[ -n "$IDENTITY" ]] || return 0
  codesign --force --sign "$IDENTITY" --preserve-metadata=identifier,entitlements "$1"
}

swift build --package-path "$ROOT/Packages/SlateKit" --scratch-path "$ROOT/DerivedData/InstallCLI" -c release --product slate --force-resolved-versions -q
mkdir -p "$BIN"
cp "$ROOT/DerivedData/InstallCLI/release/slate" "$BIN/slate.new"
sign "$BIN/slate.new"
mv -f "$BIN/slate.new" "$BIN/slate"

update_status installing
"$ROOT/Scripts/quit.sh"
rm -rf "$TARGET"
cp -R "$APP" "$TARGET"
sign "$TARGET"

/System/Library/CoreServices/pbs -update || true

COMMIT="$(git -C "$ROOT" rev-parse HEAD)"
if [[ "$ROOT" != "$SOURCE" && ! -d "$SOURCE/.git" ]]; then
  REMOTE="$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)"
  if [[ -n "$REMOTE" ]]; then
    mkdir -p "$SUPPORT"
    git clone --quiet --branch "$BRANCH" "$REMOTE" "$SOURCE" || echo "Could not clone $REMOTE; updates from the app are off until the next install."
  fi
fi
if [[ -d "$SOURCE/.git" ]]; then
  mkdir -p "$UPDATE_DIR"
  printf '{"commit": "%s", "branch": "%s", "source": "%s", "installedAt": "%s"}\n' "$COMMIT" "$BRANCH" "$SOURCE" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$UPDATE_DIR/installed.json"
fi
update_status done "$COMMIT"

open "$TARGET"
echo "Installed $TARGET and $BIN/slate (signed: ${IDENTITY:-ad-hoc})"
echo "To let Claude Code use your notes, run: claude mcp add -s user slate -- slate mcp"
echo "If Claude Code cannot find slate, use the full path: claude mcp add -s user slate -- $BIN/slate mcp"
