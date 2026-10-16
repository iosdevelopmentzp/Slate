#!/bin/zsh
set -euo pipefail

if [ $# -lt 2 ]; then
    echo "usage: Scripts/generate-vault.sh <folder> <count>" >&2
    exit 1
fi

FOLDER="$1"
COUNT="$2"

mkdir -p "$FOLDER/_attachments" "$FOLDER/.slate" "$FOLDER/_templates"
for space in Inbox Tasks Notes Daily Snippets Archive; do mkdir -p "$FOLDER/$space"; done
[ -f "$FOLDER/_attachments/sample.png" ] || head -c 204800 /dev/urandom > "$FOLDER/_attachments/sample.png"

awk -v folder="$FOLDER" -v count="$COUNT" '
function pick(list, n) { return list[int(rand() * n) + 1] }
function sentence(   n, i, out) {
    n = int(rand() * 14) + 6
    out = ""
    for (i = 0; i < n; i++) out = out (i ? " " : "") pick(words, wordCount)
    return toupper(substr(out, 1, 1)) substr(out, 2) "."
}
function hex(n,   i, out) { out = ""; for (i = 0; i < n; i++) out = out substr("0123456789abcdef", int(rand() * 16) + 1, 1); return out }
BEGIN {
    srand(42)
    wordCount = split("retain cycle audio engine delegate profile screen memory leak view model cache folder launch crash build simulator branch merge request ticket review network response parser header footer layout constraint animation timer queue thread actor task async await swift objc json yaml", words, " ")
    tagCount = split("audio memory ios network ui build crash perf review api", tags, " ")
    split("Inbox Tasks Notes Daily Snippets Archive", spaces, " ")
    for (index_ = 1; index_ <= count; index_++) {
        space = spaces[index_ % 6 + 1]
        title = "Note " index_ " " pick(words, wordCount) " " pick(words, wordCount)
        file = folder "/" space "/" title ".md"
        print "---" > file
        print "id: " hex(8) "-" hex(4) "-4" hex(3) "-a" hex(3) "-" hex(12) > file
        print "title: " title > file
        print "type: note" > file
        print "created: 2026-01-01T09:00:00+00:00" > file
        print "updated: 2026-10-01T09:00:00+00:00" > file
        print "tags: [" pick(tags, tagCount) ", " pick(tags, tagCount) "]" > file
        print "---" > file
        paragraphs = int(rand() * 38) + 3
        for (p = 0; p < paragraphs; p++) { print sentence() " " sentence() > file; print "" > file }
        todos = int(rand() * 6)
        for (t = 0; t < todos; t++) print "- [ ] " sentence() > file
        if (index_ % 3 == 0) { print "" > file; print "```swift" > file; print "let value = " index_ > file; print "```" > file }
        if (index_ % 10 == 0) { print "" > file; print "![](../_attachments/sample.png)" > file }
        close(file)
    }
}'

echo "wrote $COUNT notes to $FOLDER"
