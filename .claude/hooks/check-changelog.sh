#!/bin/zsh
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 0

INPUT="$(cat)"
if printf '%s' "$INPUT" | grep -q '"stop_hook_active": *true'; then
    exit 0
fi

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

CHANGED="$({ git diff --name-only HEAD; git ls-files --others --exclude-standard; } | sort -u)"
CODE_CHANGED="$(printf '%s\n' "$CHANGED" | grep -E '^(Slate/|Packages/|Scripts/|\.claude/)' || true)"
[ -z "$CODE_CHANGED" ] && exit 0

if printf '%s\n' "$CHANGED" | grep -qx 'CHANGELOG.md'; then
    exit 0
fi

echo "Slate: files under Slate/, Packages/, Scripts/ or .claude/ changed but CHANGELOG.md did not. Run /update-docs: add entries under [Unreleased], refresh docs/STATUS.md if the stage, decisions or next steps changed, then stop." >&2
exit 2
