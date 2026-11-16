# ADR 0025: Lists inside quotes

Status: accepted, 2026-11-16. Amends `STORAGE-FORMAT.md` section 11 and ADR 0008 (rich text with Markdown files).

## Context

Agents often write a message or a draft as a quote: a bold line, then a numbered or bulleted list, all behind `> `. Before this change, a quote held only paragraphs. A list inside it made Slate show the whole quote as a raw block: grey monospace text with every `>`, `**` and backtick on screen. The file was correct Markdown; only Slate could not show it.

## Decision

1. A quote and a callout may hold paragraphs, bulleted lists, numbered lists and checklists, with nested items and images under items as in ADR 0018.
2. In the editor, a list item inside a quote is a list item with a quote mark: it shares the group of its quote (and the callout kind, if any), it is drawn with the quote bar or the callout tint, and its text is indented by the quote indent.
3. Slate writes a blank `>` line between a paragraph and a list inside a quote, and between two lists of a different kind:

   ```
   > **Known**
   >
   > 1. Row 3
   > 2. Row 4
   >
   > - Q1. A question
   ```

   Slate also reads a list right under the paragraph, with no `>` line, and writes it back in the form above.
4. `- [ ] item` and `- [x] item` inside a quote are checklist items. The Markdown parser does not find task items inside a quote, so the reader turns a bullet that starts with `[ ] `, `[x] ` or `[X] ` into a checklist item.
5. Return on an empty list item inside a quote ends the list and stays in the quote; Backspace at the start of such an item does the same. `- `, `1. ` or `[] ` typed at the start of a quote line starts a list inside the quote.
6. A numbered list keeps the number of its first item: `5. a` and `6. b` stay 5 and 6 on save, and the editor counts on from 5. This holds for lists outside quotes too. A nested numbered list still starts at 1, because CommonMark lets a list right under the item text interrupt it only when it starts at 1.
7. A code block, a table, a heading, an image outside a list item or a second quote inside a quote is still outside the subset: the quote stays a raw block. The agent guide says so.

## Consequences

- Before this change, every numbered list was renumbered from 1 on save. A note with two lists, 1 to 4 and 5 to 8, kept 1 to 4 twice.
- A file with the form "list right under the paragraph" changes to the form of point 3 the first time Slate saves the note. The meaning stays the same in GitHub, GitLab and Obsidian.
