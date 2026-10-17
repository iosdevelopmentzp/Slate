# ADR 0009: Tables as block attachments, GFM pipe tables in the file

Status: accepted, 2026-10-17. ADR 0013 adds a width for images, also in cells (`![photo\|120](…)`). Level 1 built in milestone S6 and level 2 (images in cells) in S7, both on 2026-10-17; see `docs/STATUS.md` decisions 116 to 129.

## Context

The owner wants tables like the ones in Apple Notes, maybe with images in cells. Two facts shape the design:

1. **TextKit 2 has no table layout.** `NSTextTable` and `NSTextBlock` belong to TextKit 1; any use of them, or of `textView.layoutManager`, switches the editor to TextKit 1 for good (`PLAYBOOK.md` section 9). A table therefore cannot be "text in the text". It must be a block that the text view hosts.
2. **The file stays Markdown** (ADR 0001, ADR 0008). The only table syntax that other tools read is the GitHub pipe table: a header row, an alignment row, body rows, one line per row, inline content only. No multi-line cells, no merged cells, no nested tables exist in that syntax.

## Decision

### Model and file

- A table is one paragraph in the editor's attributed text that holds a single `NSTextAttachment` of kind `table`. Its payload is a `TableModel`: `columns: [TableColumn(alignment: left | center | right)]`, `header: [TableCell]`, `rows: [[TableCell]]`. A `TableCell` holds one line of inline content: text with bold, italic, strikethrough, inline code and links; in level 2 also inline images.
- In the file the table is a GFM pipe table, one line per row, `|` inside a cell written as `\|`, the alignment row with `:` markers kept as read. A table that `MarkdownReader` cannot parse (uneven columns, no alignment row) stays a raw block, as every other unsupported construct (`STORAGE-FORMAT.md` section 11). `STORAGE-FORMAT.md` section 11 gains the row "Table | GFM pipe table" when S6 starts.
- The first row is always the header, drawn semibold with a tinted background. GFM has no header-less table, so the editor has no "no header" option.

### Level 1: what Apple Notes does

- The format bar gets a **Table** button (`⌥⌘T`): inserts a 2 × 2 table (header plus one row) at the caret's paragraph boundary.
- Cells edit in place: a click puts the caret in the cell; the cell editor is a one-paragraph rich text field that shares the inline style commands of the main editor (`⌘B`, `⌘I`, `⌘⇧X`, `⌘K`), so bold, italic, strikethrough, code and links work inside cells. Enter in a cell does not add a line; it moves to the cell below and adds a row when on the last row. Tab and `⇧Tab` move right and left (Tab on the last cell adds a row). Arrow keys at the first or last cell leave the table into the text. Esc leaves the table.
- A thin "+" handle on hover at the right edge and the bottom edge adds a column or a row. Right click on a cell: Add row above, Add row below, Add column left, Add column right, Align left/center/right (per column), Delete row, Delete column, Delete table (inline confirm when the table has content in more than one cell).
- Column widths come from the content with a minimum of 60 pt and are shared across the text width; when the table is wider than the text column, columns shrink and text wraps inside the cell on screen (the file still holds one line per row). No manual column resize in level 1.
- Copy with the table selected copies GFM Markdown. Pasting text that parses as a GFM table inserts a table block; pasting rows from a spreadsheet (tab separated, more than one column) offers "Paste as table" in the same bar as "Paste as code" used to.
- Undo: every cell edit and every structure change registers with the document's undo manager through a snapshot of the `TableModel`, so `⌘Z` works from inside and outside the table.
- Look (`UX.md` section 3): 8 pt radius, a thin border in `Theme.border`, header background `Theme.base`, cell padding 6 × 8, body text style inside cells.

### Level 2: images in cells

- A cell may hold inline images: in the file `![](../_attachments/x.png)` inside the cell; on screen a thumbnail 80 pt high, rounded 4, next to the text of the cell. Drop an image on a cell, paste into a cell, or the Image button while a cell is active, import through the same handler as the main editor. Double-click opens Quick Look; Delete removes the image when it is selected.
- Level 2 starts only after level 1 passed the owner's check; the model already allows it (a `TableCell` is inline content).

### Out of scope, by the file format

Multi-paragraph cells (line breaks inside a cell came later as `<br>`, ADR 0012), lists inside cells, merged cells, nested tables, row heights, cell colours, formulas. A user who needs those writes a list or a note per row.

## Consequences

- Tables look and behave like a native block; the file stays readable everywhere.
- The attachment view needs careful focus handling: the text view's selection does not reach inside the table, so the table block owns its own focus state and tells the editor when the caret leaves it. Accessibility: the block exposes table, row and cell roles.
- Performance: the view provider is lazy; a note with many tables builds views for the visible ones only.
- A second attachment kind next to images means a small `BlockAttachmentKind` enum in `SlateEditor/Blocks/` that images and tables share.

## Alternatives rejected

- `NSTextTable` on TextKit 1: a one-way door that costs TextKit 2 (paragraph styling, lazy layout, the image blocks).
- A read-only grid with a popover editor: breaks the "edit in place" rule and feels like a form.
- An own table syntax with richer cells: unreadable by Obsidian, GitHub and the CLI.

## Milestone S6: tables, level 1

Scope: `TableModel`, `TableBlockAttachment` and its view, the Table button and `⌥⌘T`, cell editing with inline styles, keyboard rules, hover handles, the context menu, column widths, copy and paste, undo, `MarkdownReader` and `MarkdownWriter` support with `\|` escaping, the raw-block fallback, `STORAGE-FORMAT.md` section 11 row, `UX.md` component row.

Tests: `TableMarkdownTests` (round trip over fixtures with alignment, escaped pipes, inline styles, a broken table that stays raw), `TableModelTests` (every row and column operation, undo snapshots), `TablePasteTests` (GFM text, tab-separated text), an editor test that Tab on the last cell adds a row.

Done when: insert a table, fill four cells with Tab, make one word bold, add a column from the handle, close the note: the file holds one GFM table; reopen: it looks the same; `⌘Z` undoes the last cell edit; a note from Obsidian with a table keeps the table byte for byte after a save that touched another paragraph.

Level 2 is a separate entry in `ROADMAP.md` once level 1 is accepted.
