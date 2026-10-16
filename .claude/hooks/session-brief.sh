#!/bin/zsh
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 0

echo "## Slate session brief"
echo
echo "### Recent commits"
git log --oneline -10 2>/dev/null || echo "(no git history yet)"
echo
echo "### Uncommitted changes"
CHANGES="$(git status --short 2>/dev/null)"
if [ -n "$CHANGES" ]; then echo "$CHANGES"; else echo "(clean)"; fi
echo
echo "### CHANGELOG.md — Unreleased"
UNRELEASED="$(awk '/^## \[Unreleased\]/{flag=1; next} /^## \[/{flag=0} flag' CHANGELOG.md | sed '/^$/d')"
if [ -n "$UNRELEASED" ]; then echo "$UNRELEASED"; else echo "(empty)"; fi
echo
echo "### docs/STATUS.md"
cat docs/STATUS.md
echo
echo "Rule: before this session ends, record changed behaviour in CHANGELOG.md under [Unreleased] and refresh docs/STATUS.md when the stage, a decision or the next steps change. Use /update-docs."
