#!/bin/zsh
set -uo pipefail

SOURCE="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$HOME/Library/Application Support/Slate/update"
LOCK="$DIR/update.lock"
BRANCH="${SLATE_UPDATE_BRANCH:-main}"
mkdir -p "$DIR"

if [[ -e "$LOCK" ]] && kill -0 "$(cat "$LOCK" 2>/dev/null)" 2>/dev/null; then
    echo "An update is already running."
    exit 0
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT

export SLATE_UPDATE_STATUS="$DIR/status.json"
export SLATE_UPDATE_STARTED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
source "$SOURCE/Scripts/update-status.sh"

update_status fetching
if ! git -C "$SOURCE" fetch --quiet origin "$BRANCH" || ! git -C "$SOURCE" reset --quiet --hard "origin/$BRANCH"; then
    update_status failed "" "Slate could not get the changes from git."
    exit 1
fi

if ! "$SOURCE/Scripts/install.sh"; then
    update_status failed "$(git -C "$SOURCE" rev-parse HEAD)" "The build failed."
    exit 1
fi
