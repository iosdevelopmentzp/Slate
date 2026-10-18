#!/bin/zsh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GIT_DIR="$(git -C "$ROOT" rev-parse --absolute-git-dir)"
LOCK="$GIT_DIR/slate-install.lock"
PENDING="$GIT_DIR/slate-install.pending"
LOG="$GIT_DIR/slate-install.log"

[ "$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)" = "main" ] || exit 0
if git -C "$ROOT" diff --quiet 'HEAD@{1}' HEAD -- Slate Config Packages Slate.xcodeproj Scripts 2>/dev/null; then
    exit 0
fi

notify() {
    osascript -e "display notification \"$1\" with title \"Slate\"" >/dev/null 2>&1 || true
}

touch "$PENDING"
if [ -e "$LOCK" ] && kill -0 "$(cat "$LOCK" 2>/dev/null)" 2>/dev/null; then
    exit 0
fi

(
    echo $$ > "$LOCK"
    trap 'rm -f "$LOCK"' EXIT
    while [ -e "$PENDING" ]; do
        rm -f "$PENDING"
        if "$ROOT/Scripts/install.sh" > "$LOG" 2>&1; then
            notify "Installed $(git -C "$ROOT" rev-parse --short HEAD)"
        else
            notify "Install failed, see .git/slate-install.log"
        fi
    done
) < /dev/null > /dev/null 2>&1 &!
