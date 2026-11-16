# ADR 0026: File cards

Status: accepted, 2026-11-16. Amends `STORAGE-FORMAT.md` section 11 and `SPEC.md` 5.4.

## Context

Slate copies a dropped or pasted file into `_attachments/` and writes `[<name>](../_attachments/<file>)` into the note. Until now the editor showed that as a plain text link. `SPEC.md` 5.4 asked for a chip with an icon. The owner wants to see a file as a file, open it with a double-click and find it in Finder.

## Decision

1. A paragraph line that holds only a link, with a plain name and a target inside `_attachments/` or a `file://` URL, is a file card: a block of kind `.file` with the target and the name.
2. The card shows the Finder icon of the file, its name, its kind and its size. A missing file shows "File not found" with the icon of its type.
3. Double-click opens the file. The menu has Open, Quick Look, Show in Finder, Save to Downloads and Remove.
4. The file format does not change: the card is written back as `[<name>](<target>)`. Like an image, the card is its own block, so Slate writes a blank line before and after it. A link inside a sentence, inside a list item, inside a quote or with a styled name stays a text link.
5. Dragging a card out to Finder is not part of this decision.

## Consequences

- A note with several file links on lines next to each other gets blank lines between them the first time Slate saves it. GitHub, GitLab and Obsidian show the same links.
- The agent guide tells agents to put a file link on its own line.
