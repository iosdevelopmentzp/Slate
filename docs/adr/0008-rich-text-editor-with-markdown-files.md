# ADR 0008: A rich text editor on TextKit 2, Markdown stays the file format

Status: accepted, 2026-10-16. Replaces ADR 0005 (thin Markdown editor with visible marks).

## Context

The owner wants to format like in Apple Notes: a button or a shortcut makes a title, a heading, bold text or a list, and an image sits in the text, not under a line of Markdown. The files must stay Markdown (ADR 0001, Obsidian, the CLI, Claude Code).

## Decision

- **What the user sees is formatted text.** No Markdown marks on screen. `NSTextView` on TextKit 2 in rich text mode, inside the `SlateEditor` module. The module gains one dependency: `swift-markdown`, used only under `SlateEditor/Markdown/`.
- **The file is Markdown.** On open, `MarkdownRichText.read(markdown) -> NSAttributedString`. On save, `MarkdownRichText.write(attributed) -> String`. Both are pure functions with tests. The editor never writes a file.
- **A fixed subset of Markdown**, listed in `STORAGE-FORMAT.md` section 11. Each block paragraph carries a custom attribute `slate.block` (`title`, `heading`, `subheading`, `body`, `monospaced`, `quote`, `bullet`, `numbered`, `checklist(done)`, `image(path)`, `divider`, `raw`) and an indent level 0 to 2; inline runs carry `slate.inline` flags (`bold`, `italic`, `strikethrough`, `code`) and `NSAttributedString.Key.link` for links.
- **Nothing is lost on round trip.** A block the subset cannot represent (a table, an HTML block, a nested structure deeper than two levels, a footnote, a reference link definition) becomes a `raw` block: shown in monospaced on a light background, editable as plain text, written back exactly as it was. A test over the fixture set checks `write(read(x)) == x` for every file Slate wrote, and "same AST" (swift-markdown) for files from other tools.
- **Images are blocks.** An image is its own paragraph holding one `NSTextAttachment` whose cell draws the image scaled to the text width (at most 360 pt high) and carries the attachment path in `slate.block`. Paste, drag and drop and the Image button insert one at the caret's paragraph boundary. Written as `![](../_attachments/name.png)` on its own line. Double-click opens Quick Look; Delete removes the block.
- **Formatting commands** live in `SlateEditor/Commands/` and act on the selection or the typing attributes: paragraph styles (Title `⇧⌘T`, Heading `⇧⌘H`, Subheading `⇧⌘J`, Body `⇧⌘B`, Monospaced `⇧⌘M`), lists (Checklist `⇧⌘L`, Bulleted `⇧⌘7`, Numbered `⇧⌘9`), Quote `⌘'`, Bold `⌘B`, Italic `⌘I`, Strikethrough `⌘⇧X`, Link `⌘K`, Image `⇧⌘I`, Divider. The same commands sit in the format bar above the text and in the Format menu. The shortcuts follow Apple Notes where it has them.
- **List behaviour**: Enter continues a list; Enter on an empty item ends the list; Tab and `⇧Tab` indent and outdent up to level 2; a click on a checklist box toggles it; Backspace at the start of an item turns it into body text.
- **Styles are fixed, not a palette:** Title 24 bold, Heading 18 semibold, Subheading 15 semibold, Body 15, Monospaced 13 (SF Mono), quote in secondary colour with a 3 pt bar, line height 1.4 for body. The text size setting scales all of them.
- **Undo** goes through `NSTextView`'s undo manager for every command (edits through `shouldChangeText` and `didChangeText`).
- **Code blocks** are the `monospaced` style: one paragraph style, no language label, no highlighting in v1. The language of an existing fence is kept in the block attribute and written back.

## Consequences

- The screen looks like Notes. Markdown is invisible but intact.
- Some Markdown cannot be made with the buttons (tables, HTML); those files show raw blocks. Acceptable for v1.
- Highlighting of code and the Markdown-mark styling of M2 are parked; the M2 code is removed from Presentation and kept in git history.
- The round-trip tests are the safety net; the fixture set must include files from Obsidian and files with every subset element.

## Alternatives rejected

- Keep the Markdown source editor and add a format bar that inserts marks: still shows `**` and `#` on screen; the owner does not want that.
- `TextEditor` with `AttributedString` (SwiftUI): formatting commands and list behaviour would be built from scratch; `NSTextView` gives undo, selection, typing attributes and attachments for free.
- RTF or HTML as the file format: breaks ADR 0001 and every other tool.
