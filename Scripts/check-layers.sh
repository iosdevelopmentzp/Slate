#!/bin/zsh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/Packages/SlateKit/Sources"
TESTS="$ROOT/Packages/SlateKit/Tests"
HOST="$ROOT/Slate"
EXCEPTIONS="$ROOT/Scripts/layer-exceptions.txt"
MODULES=(SlateDomain SlateData SlateMocks SlateUI SlateEditor SlatePresentation SlateComposition SlateTestSupport SlateCLI)
STATUS=0

report() {
    echo "layers: $1"
    STATUS=1
}

forbid() {
    local dir="$1" pattern="$2" reason="$3" exclude="${4:-}"
    [ -d "$SRC/$dir" ] || return 0
    local matches
    if [ -n "$exclude" ]; then
        matches="$(grep -rEn --include='*.swift' "$pattern" "$SRC/$dir" | grep -Ev "$exclude" || true)"
    else
        matches="$(grep -rEn --include='*.swift' "$pattern" "$SRC/$dir" || true)"
    fi
    [ -z "$matches" ] && return 0
    report "$reason"
    printf '%s\n' "$matches" | sed "s#^$ROOT/#  #"
}

forbid SlateDomain '^import (SwiftUI|AppKit|Cocoa|Observation|Combine|GRDB|Markdown)' 'SlateDomain imports a UI, app or data framework'
forbid SlateDomain '\b(Process|UserDefaults|NSWorkspace|NSPasteboard|NSScreen|NSPanel|NSFileCoordinator)[.(]|\bNSApp\b|FileManager\.default' 'SlateDomain touches the system directly'

forbid SlateData '^import (SwiftUI|Observation)' 'SlateData imports SwiftUI or Observation'
forbid SlateData '^import AppKit' 'SlateData imports AppKit outside SlateData/System' '/SlateData/System/'
forbid SlateData '\.shared\b' 'SlateData uses a shared singleton' 'URLSession\.shared|NSWorkspace\.shared'
forbid SlateData '\bProcess\(' 'SlateData runs a process outside ShellRunner' '/SlateData/Shell/ShellRunner\.swift:'
forbid SlateData '\bUserDefaults\b' 'SlateData uses UserDefaults outside UserDefaultsKeyValueStore' '/SlateData/Persistence/UserDefaultsKeyValueStore\.swift:'
forbid SlateData 'NSFileCoordinator' 'SlateData coordinates files outside SlateData/Files' '/SlateData/Files/'
forbid SlateData '^import GRDB' 'SlateData imports GRDB outside SlateData/Index' '/SlateData/Index/'
forbid SlateData '^import Markdown' 'SlateData imports Markdown outside SlateData/Index or SlateData/Export' '/SlateData/(Index|Export)/'

forbid SlateMocks '^import (SwiftUI|AppKit|Observation|GRDB|Markdown)' 'SlateMocks imports a UI or data framework'

forbid SlateUI '^import Slate' 'SlateUI imports a Slate module'

forbid SlateEditor '^import Slate' 'SlateEditor imports a Slate module'
forbid SlateEditor 'NSPasteboard' 'NSPasteboard used outside SlateEditor/Paste' '/SlateEditor/Paste/'
forbid SlateEditor '\blayoutManager\b' 'SlateEditor touches the TextKit 1 layoutManager (use textLayoutManager)'

forbid SlatePresentation '^import SlateData' 'SlatePresentation imports SlateData'
forbid SlatePresentation '^import (GRDB|Markdown)' 'SlatePresentation imports a data framework'
forbid SlatePresentation '^import SlateMocks' 'SlatePresentation imports SlateMocks outside PresentationAssembly+Preview.swift' '/SlatePresentation/Shared/PresentationAssembly\+Preview\.swift:'
forbid SlatePresentation '\bProcess\(' 'SlatePresentation runs a process'
forbid SlatePresentation '\.shared\b' 'SlatePresentation uses a shared singleton' 'NSWorkspace\.shared|NSApplication\.shared|NSStatusBar\.system|NSApp\b'
forbid SlatePresentation 'NSPasteboard' 'NSPasteboard used outside SlatePresentation/Shared/PasteboardWriter.swift' '/SlatePresentation/Shared/PasteboardWriter\.swift:'
forbid SlatePresentation '\bUserDefaults\b' 'SlatePresentation uses UserDefaults'

forbid SlateCLI '^import (SwiftUI|AppKit|SlatePresentation|SlateUI|SlateEditor|SlateComposition)' 'SlateCLI imports a UI module'

for module in SlateDomain SlateData SlateMocks SlateTestSupport SlateCLI; do
    forbid "$module" '^nonisolated ' "$module declares nonisolated at the top level (it is the module default)"
done

matches="$(grep -rEn --include='*.swift' '\bpublic\b' "$SRC" "$TESTS" | grep -v "^$SRC/SlateComposition/" || true)"
if [ -n "$matches" ]; then
    report 'public used outside SlateComposition'
    printf '%s\n' "$matches" | sed "s#^$ROOT/#  #"
fi

matches="$(grep -rEn --include='*.swift' '@testable' "$SRC" "$HOST" || true)"
if [ -n "$matches" ]; then
    report '@testable used outside Packages/SlateKit/Tests'
    printf '%s\n' "$matches" | sed "s#^$ROOT/#  #"
fi

matches="$(grep -rEn --include='*.swift' '^\s*//' "$SRC" "$TESTS" "$HOST" | grep -Ev '//\s*MARK' || true)"
if [ -n "$matches" ]; then
    report 'comment lines found (names and small functions carry the meaning)'
    printf '%s\n' "$matches" | sed "s#^$ROOT/#  #"
fi

matches="$(find "$HOST" -name '*.swift' -type f | grep -vx "$HOST/SlateApp.swift" || true)"
if [ -n "$matches" ]; then
    report 'Slate/ holds Swift files other than SlateApp.swift'
    printf '%s\n' "$matches" | sed "s#^$ROOT/#  #"
fi
[ -f "$HOST/SlateApp.swift" ] || report 'Slate/SlateApp.swift is missing'

exceptions="$( [ -f "$EXCEPTIONS" ] && grep -Ev '^\s*(#|$)' "$EXCEPTIONS" | sed -E 's/\s+#.*$//' || true )"

check_file_rule() {
    local root="$1"
    [ -d "$root" ] || return 0
    while IFS= read -r file; do
        relative="${file#$ROOT/}"
        printf '%s\n' "$exceptions" | grep -qx "$relative" && continue
        name="$(basename "$file" .swift)"
        primary="${name%%+*}"
        declared="$(grep -E '^(nonisolated |final |indirect |public |package |internal |@[A-Za-z]+ )*(struct|class|enum|protocol|actor) [A-Za-z_][A-Za-z0-9_]*' "$file" | sed -E 's/^.*(struct|class|enum|protocol|actor) ([A-Za-z_][A-Za-z0-9_]*).*/\2/' || true)"
        extended="$(grep -E '^(nonisolated |public |package |internal |@[A-Za-z]+ )*extension [A-Za-z_][A-Za-z0-9_.]*' "$file" | sed -E 's/^.*extension ([A-Za-z_][A-Za-z0-9_]*).*/\1/' | grep -vx "$primary" | grep -vx "$name" || true)"
        count=$(( $(printf '%s' "$declared" | grep -c . ) + $(printf '%s' "$extended" | grep -c . ) ))
        if [ "$count" -gt 1 ]; then
            report "$relative holds more than one top-level type: $(printf '%s\n%s' "$declared" "$extended" | grep . | tr '\n' ' ')"
        fi
        if [ "$count" -ge 1 ] && ! printf '%s\n%s\n' "$declared" "$extended" | grep -qx "$primary"; then
            report "$relative: file name does not match a declared type ($(printf '%s\n%s' "$declared" "$extended" | grep . | tr '\n' ' '))"
        fi
    done < <(find "$root" -name '*.swift' -type f)
}

for module in $MODULES; do
    check_file_rule "$SRC/$module"
done
check_file_rule "$TESTS"

if [ "$STATUS" -eq 0 ]; then
    echo "layers: ok"
fi
exit $STATUS
