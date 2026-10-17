# ADR 0013: An image's width is a `|width` suffix in its alt text

Status: accepted, 2026-10-17. Amends `STORAGE-FORMAT.md` section 11 (images) and ADR 0009 level 2 (images in cells).

## Context

The owner wants to change the size of an image, both in the note text and in a table cell. CommonMark has no place for a size. HTML `<img width>` would make the paragraph a raw block in Slate (ADR 0008) and in a table cell would make the whole table a raw block (ADR 0012). Obsidian reads a width from the alt text: `![photo|300](path)` shows the image 300 points wide, and `![photo|300x200](path)` gives width and height.

## Decision

- An image's alt text may end with `|<width>` or `|<width>x<height>`, numbers only. The part before the `|` is the alt text proper.
- Slate reads the width and shows the image at that width, at most as wide as the text, with the height from the picture's aspect ratio. A height in the suffix is kept in the file but not used.
- Slate writes a size only when the user changes it, as `|<width>` in whole points, and removes the suffix for "Original Size" or "Default Size". Every other image keeps its alt text byte for byte.
- In a table cell the `|` is written as `\|`, as for any pipe in a cell (ADR 0009), so `![photo\|160](path)`. Obsidian reads it the same way.
- Without a suffix nothing changes: an image in the text is as wide as the text allows up to 360 points high, a cell thumbnail is 80 points high.

## Consequences

- The size works the same in Slate and Obsidian. GitHub and other Markdown tools show the full image and use `photo|300` as its alt text.
- An alt text that happens to end in `|` and a number, such as `step 1|2`, is read as a size. Obsidian has the same rule.
- The reader and the writer need no change: the alt text already round-trips. Only the display and the commands that change the size know the suffix.
