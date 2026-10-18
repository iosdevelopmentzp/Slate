#!/bin/zsh
set -euo pipefail

pgrep -x Slate >/dev/null || exit 0
osascript -e 'tell application id "local.slate.app" to quit' >/dev/null 2>&1 || true

for _ in {1..50}; do
    pgrep -x Slate >/dev/null || exit 0
    sleep 0.2
done
pkill -x Slate || true
