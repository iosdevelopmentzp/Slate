# ADR 0018: Images inside lists

Status: accepted, 2026-10-27. Amends `STORAGE-FORMAT.md` section 11 and ADR 0008 (rich text with Markdown files).

## Context

The owner often wants a screenshot between the steps of a list: step 1, its screenshot, step 2. Before this change, a list item held one line of text and its nested items. An image inside an item made Slate show the whole list as a raw block. An image between two items, outside the list, split it into two lists, and the second list started again at 1.

Agents met the same problem: `attach_image` could only add an image at the end of a note or a section.

## Decision

1. In the file, an image under a list item is its own paragraph inside the item: a blank line, the image line indented to the start of the item text, a blank line. This is plain CommonMark, and Obsidian and GitHub show the image under the item.

   ```
   1. Open the app

      ![](../_attachments/20261027-080631-agent.png)

   2. Tap Delete
   ```

2. Slate also reads an image line right under the item text with no blank line (`1. Open the app` and then `![](…)` on the next line), and writes it back in the form of point 1.
3. In the editor, such an image is an image block with an indent: the level of its item plus one, and the group of its list. It is drawn at the start of the item text. It does not end the list, so the numbers go on after it.
4. An image added in the editor while the caret is in a list item goes under that item. Return after such an image starts the next item of the same list.
5. Text after an image inside the same item (a second paragraph) is still outside the subset: the list stays a raw block.
6. `attach_image` takes `after`: a piece of text from one line. Slate puts the image under that line, its paragraph or its list item, with the indent of point 1.

## Consequences

- A list with an image is a "loose" list in CommonMark, so other apps may show more space between its items.
- A file with the form of point 2 changes to the form of point 1 the first time Slate saves the note.
