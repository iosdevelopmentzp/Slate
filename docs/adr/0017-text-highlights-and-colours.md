# ADR 0017: Highlights and text colours

Status: accepted, 2026-10-20. Amends `STORAGE-FORMAT.md` section 2.4 and ADR 0008 (rich text with Markdown files).

## Context

The owner wants to mark text with colours: a coloured background (a highlighter) and coloured letters. CommonMark has no colours. Before this change, inline HTML made the paragraph a raw block in Slate (ADR 0008), so colours written by other tools showed as tags.

Obsidian shows `==text==` as a yellow highlight. The Obsidian plugin Highlightr writes other colours as `<mark style="background: #FFB8EBA6;">text</mark>`. Obsidian also shows `<span style="color: …">` as coloured letters. GitHub shows `<mark>` and drops the style of `<span>`.

## Decision

1. Two fixed palettes:
   - **Highlight**: yellow `#FFF3A3A6`, green `#BBFABBA6`, blue `#ADCCFFA6`, pink `#FFB8EBA6`, purple `#D2B3FFA6` (the Highlightr colours).
   - **Text colour**: red `#E5484D`, orange `#F76B15`, green `#30A46C`, blue `#0090FF`, grey `#8B8D98`.
2. In the file:
   - A yellow highlight is `==text==`.
   - Another highlight is `<mark style="background: #RRGGBBAA;">text</mark>`.
   - A text colour is `<span style="color: #RRGGBB;">text</span>`.
   - When text has both, the highlight is outside: `==<span style="color: #E5484D;">text</span>==`.
3. Slate reads these tags with or without the `;`, in any letter case, and also reads `background-color:` and `<mark style>` with the yellow value. It writes exactly the forms in point 2.
4. A tag with a colour outside the palette, a tag without its closing tag, or any other inline HTML keeps the paragraph a raw block, as before. Slate never loses a colour it cannot show.
5. `==` makes a highlight only as a pair of exactly two `=` signs, where the opening pair is followed by a non-space and the closing pair comes after a non-space. `a == b` and `x === y` stay text. Slate writes `\=\=` for a plain `==` that could open or close a highlight, and `\=` for a plain `=` next to a highlight.
6. Inside the editor the colour is part of the inline style (`InlineStyle` bits 8 to 11 for the highlight, 12 to 15 for the text colour), so it moves with the text like bold does: through typing, copy and paste, table cells and undo.

## Consequences

- Highlights look the same in Slate and Obsidian with Highlightr. Without the plugin, Obsidian still shows all colours, because it renders the HTML.
- GitHub shows the yellow `==` as plain `==text==` and the other highlights as yellow `<mark>`. Text colours are lost on GitHub.
- A file with other colours, for example from another plugin, stays readable: its paragraphs are raw blocks and are written back byte for byte.
- The note card preview drops the tags and the `==`.
- A highlight that crosses a link, a line break or a table cell edge is written as two highlights.
