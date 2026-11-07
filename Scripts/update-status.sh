#!/bin/zsh

update_status() {
    [[ -n "${SLATE_UPDATE_STATUS:-}" ]] || return 0
    local phase="$1" commit="${2:-}" message="${3:-}"
    local started="${SLATE_UPDATE_STARTED:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
    mkdir -p "$(dirname "$SLATE_UPDATE_STATUS")"
    printf '{"phase": "%s", "startedAt": "%s", "commit": "%s", "message": "%s"}\n' "$phase" "$started" "$commit" "$message" > "$SLATE_UPDATE_STATUS.tmp"
    mv -f "$SLATE_UPDATE_STATUS.tmp" "$SLATE_UPDATE_STATUS"
}
