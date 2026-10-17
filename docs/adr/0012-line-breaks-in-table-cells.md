# ADR 0012: Line breaks in table cells are `<br>` in the file

Status: accepted, 2026-10-17. Amends ADR 0009 ("Out of scope, by the file format").

## Context

ADR 0009 keeps a table cell to one line of inline content, because a GFM pipe table has one line per row. The owner wants several lines of text in one cell. GitHub and Obsidian already show `<br>` inside a pipe table cell as a line break, and many tables from other tools use it. Today such a table stays a raw block in Slate.

## Decision

- Inside a table cell, the tag `<br>` (also `<br/>`, `<br />`, any case) is a line break. In the editor it is a U+2028 line break in the cell text, the same character the editor uses for a line break inside other blocks.
- Slate writes a line break in a cell as `<br>`. Empty lines at the start and the end of a cell are dropped on write. A `<br>` that the user types as text is written as `\<br>`, so it stays text.
- Keys in a cell: `⇧Enter`, `⌥Enter` and `⌃Enter` start a new line in the cell. Enter still moves to the cell below. ↑ and ↓ move between the lines of the cell before they move to another cell. Pasted text keeps its lines.
- Only `<br>` is read. Any other HTML in a cell keeps the table a raw block, and `<br>` outside a table cell keeps the paragraph a raw block, as before.
- An unchanged table is still written back byte for byte (ADR 0009), so `<br/>` from another tool stays `<br/>` until the cell changes.

## Consequences

- Cells can hold several lines of text with inline styles, links and images. Lists, quotes and several paragraphs in a cell stay out of scope.
- A plain text editor shows the `<br>` tags.
- `STORAGE-FORMAT.md` section 11 gains the rule in the table row.
