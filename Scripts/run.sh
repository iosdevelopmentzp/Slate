#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$("$ROOT/Scripts/build.sh" Debug | tail -1)"

pkill -x Slate || true
open "$APP"
echo "Launched $APP"
