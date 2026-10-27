# UX rule book (revision 2, 2026-10-16)

The owner's requirement: **a high-quality interface that is simple to understand, friendly and soft, not strict.** The first build looked austere: thin dividers, dense rows, chips everywhere, Markdown marks in the text. This revision turns the requirement into rules an agent can check. Every screen, row, banner and setting is compared with it before a milestone is called done.

Reference points: Apple Notes (list and editor, calm), Bear (warm, rounded, one accent), Things 3 (keyboard, quick entry, soft cards). Slate copies their restraint and their softness.

---

## 1. Principles

1. **Native, but soft.** Standard AppKit and SwiftUI controls, the system font, SF Symbols, system colours, light and dark. On top of that: rounded corners everywhere (section 3), cards instead of dividers, generous spacing, one warm accent colour, tinted folder icons. No custom fonts, no gradients, no custom window chrome.
2. **Two visible concepts.** Folders and Notes. Plus search, pin and Trash. Nothing else appears in the app in v1 (ADR 0007).
3. **One obvious action per place.** The sidebar has "New folder", the list has "New note", the editor has the text and the format bar, the quick note field has Enter. Secondary actions appear on hover or in a right-click menu.
4. **Formatting by buttons and shortcuts, never by syntax.** The text on screen is formatted text (ADR 0008). A user who never learns a shortcut can do everything with the format bar.
5. **Keyboard first, mouse complete.** Every action has a shortcut and a menu entry, and every action can also be done with the mouse.
6. **No modal dialogs.** No alerts, no sheets. Destructive actions confirm inline ("Delete? Yes · No") and show a toast with Undo for five seconds.
7. **Instant.** A click or a keystroke shows its result at once; longer work runs in the background with a small indicator and never blocks typing.
8. **Plain words.** Short, common words (section 7). No internal terms.
9. **Empty states help.** One friendly sentence and the one action that fills the screen.
10. **Forgiving.** Autosave, Undo everywhere, a Trash, versions. Never "Are you sure?".

## 2. Layout

Slate is one normal window with three columns (ADR 0016). It has a Dock icon and a menu bar icon. The close button and `⌘W` hide the window and give the focus back to the previous app; the Dock icon, a left click on the menu bar icon or `⌥⌘N` shows it again on the desktop you are on, with the same folder and note. When the window is already in front, the menu bar icon and `⌥⌘N` hide it. The window remembers its frame, and at launch it is open or hidden as it was when Slate quit.

```
┌───────────────────────────────────────────────────────────────────────────────┐
│ ● Folders        │ Notes                     [+]  │                            │
│                  │ ( Search              )        │  Title                     │
│ 📁 Notes      12 │ ┌────────────────────────────┐ │  ─ format bar ─────────    │
│ 📁 Ideas       4 │ │ Title            2 min     │ │                            │
│ 📁 Work        9 │ │ preview preview preview…   │ │  Body text, formatted.     │
│                  │ └────────────────────────────┘ │  • a list                  │
│                  │ ┌────────────────────────────┐ │  ☐ a checklist item        │
│                  │ │ Title            Yesterday │ │  ┌──────────────────┐      │
│                  │ │ preview…                   │ │  │      image       │      │
│ 🗑 Trash         │ └────────────────────────────┘ │  └──────────────────┘      │
│ [+ New folder]   │                                │                            │
└───────────────────────────────────────────────────────────────────────────────┘
```

- Default 1040 × 680, minimum 820 × 520. Sidebar 220 pt (draggable 180 to 300, double-click for 220, collapsible with `⌘0` or the sidebar button in its header, both remembered; a folder name that does not fit shows in full in a hint), list 320 pt (draggable 260 to 420, collapsible with `⌥⌘0` or the list button at the top left of the note, both remembered), editor the rest. With the folders hidden, the list header starts with a button that shows them; with both hidden, both buttons sit at the top left of the note, after the window buttons. Picking a folder, `⌘1`…`⌘9` or a search of all notes shows the list again.
- **Sidebar**: the folders as rows with a tinted `folder.fill` icon in the folder's colour, the name, and the count in secondary text. Trash at the bottom of the folder list. "New folder" is a soft button at the very bottom. Selection is a rounded pill (section 3). Right click on a folder: Rename, Colour (eight dots), Icon, Move up, Move down, Delete folder (inline: "Delete 'Ideas'? Its 4 notes move to Notes. Yes · No"). Double click renames inline. Drag a note row onto a folder to move it. Drag a folder onto another folder to move it inside; drop it on the "Folders" header to make it a top-level folder. The toast has Undo. The folder for quick notes and projects stay at the top level. Sub-folders (ADR 0011) show under their folder as a tree: an arrow before a folder that has sub-folders shows or hides them (remembered), sub-folder rows are indented 14 pt, use an outline folder icon in the colour of their top-level folder, and have New folder inside, Rename and Delete folder in the right-click menu. Every folder's menu starts with New folder inside. **Projects** (ADR 0014) have their own section under the folders: a "Projects" label with a + menu (New Project, Import Folder…; a folder dropped from Finder on the label is imported too), then the project rows with the `shippingbox.fill` icon, the same tree and the same menu. With no project, one line of secondary text explains what a project is. The menu of a top-level folder ends with Make a Project; the menu of a project ends with Link Repository… (or Change Repository…) and Make a Folder. Move up and Move down stay inside the section. A project's menu starts with **New Task**: an inline field under the project ("ABC-123 Task title"); Enter makes the task folder and its note and opens both. In the list of a project, task folders show a filled check icon and a status pill (To do grey, In progress blue, In review orange, Done green, Dropped secondary) and are sorted in progress, in review, to do, done, dropped. The editor of a task note in a project shows one line under the title: the status pill as a menu with the five statuses, the ticket and the branch (click copies).
- **List**: the folder name as a title (`.title2` semibold) with a round "+" button on the right and a sort menu (`arrow.up.arrow.down`: Date Edited, Date Created, Title; one choice for every list, remembered; pinned notes stay first; not in the Trash); a rounded search field under it; then **note cards**: 12 pt padding, 10 pt radius, 6 pt gap, surface colour, a soft selection tint when selected, a slightly stronger tint on hover. Card content: title (one line, semibold), relative date on the right in secondary, a two-line preview in secondary, a small pin glyph at the top-right when pinned. Hover shows one round "…" button at the right edge of the card with: Pin, Move to ▸, Duplicate, Copy Path, Copy Link, Move to Trash. The same in the right-click menu. A card dragged out of Slate (into a terminal, an agent window, Finder) carries the note's file (ADR 0010). In a folder with sub-folders, the sub-folders come first as rows (folder icon, name, count, a chevron, 40 pt high, the card radius); a click opens the sub-folder, a note card dropped on the row moves the note there. The list of a folder shows only the notes directly in it. Inside a sub-folder a back chevron before the title goes to the parent. After the notes comes a **Files** section (ADR 0014) with every other file directly in the folder: a 32 pt icon or image thumbnail, the name, the size and the date. Double click opens Quick Look; hover shows "…" with Quick Look, Open, Show in Finder, Save to Downloads, Copy Path, Rename, Move to Trash (to the macOS Trash, with Undo in a toast). A row dragged out carries the file. Files dropped from Finder on the list are copied into the open folder; the list shows an accent outline while they hover.
- **Editor**: the title as a large field (24 pt bold, no border, placeholder "Title"; `⌥`-click copies the file path; on its right a "↩ 3" capsule when other notes link here (a popover lists them with the line around each link; a click opens the note), a share button with Export as PDF and Export as HTML (the file goes to Downloads and shows in Finder), a magnifier for Find in Note (`⌥⌘F`: the find bar over the text, with every match marked, ⌘G and ⇧⌘G for the next and previous match, and Replace), a list button for Go to Heading (`⇧⌘O`: a menu of the headings, indented by level, the current section ticked) and the clock for versions), under it the **format bar** (section 4), then the text with 24 pt side padding and a maximum text width of 720 pt centred when the column is wider. A heading shows a small arrow on its left on hover; a click collapses the text under it up to the next heading of the same or a higher level, and the arrow then stays, pointing right. Collapsing changes only the view, never the file; Slate remembers it per note. A note opened from search shows every search word marked in yellow until the next edit, Esc or another note. Under the editor nothing: no footer, no chips. The saved state shows as a quiet "Saved" that fades in the top-right corner for a second after a save.
- **Quick note field** (`⌃⌥Space`): 520 pt wide, 14 pt radius, a soft shadow, the text at 15 pt, a bottom row with the folder menu on the left and "⏎ Save" on the right. Enter saves, `⌘Enter` saves and opens, `⇧Enter` is a new line, Esc closes and keeps the draft.
- **Settings**: one window, two pages in a sidebar, General (notes folder with Choose…, Open at login, Appearance, Text size, Back up to: a git address and "Back up now", Trash days, AI access: one switch per folder that agents may change, "Allow agents to create notes", "Allow agents to move notes to the Trash", and the line `claude mcp add -s user slate -- slate mcp` with a Copy button) and Shortcuts (three recorders: Open Slate, Quick note, New note). A "Check-up" box at the bottom of General with three one-line checks (notes folder, versions, search) and "Rebuild search".
- **First launch**: one small rounded window, "Where should Slate keep your notes?", the default path, Choose…, a big accent "Start" button. After Start the window opens on the welcome note.

## 3. Spacing, type, colour, shape

| Token | Value |
|---|---|
| Spacing scale | 4, 8, 12, 16, 24, 32 |
| Card padding | 12; card gap 6; column padding 12 |
| Corner radius | 6 buttons and fields inside bars, 8 selection pills and toolbar groups, 10 note cards and the format bar, 12 panels and the editor surface, 14 the quick note field, 999 round buttons |
| Sidebar row | 30 pt high, 8 pt radius selection pill in the accent at 14 % (light) / 22 % (dark), icon 16 pt in the folder colour |
| List card title | `.body` semibold, one line |
| List card preview | `.subheadline` secondary, two lines |
| List card date | `.caption` secondary, relative ("2 min", "Yesterday", "Oct 3") |
| Editor title | 24 pt bold |
| Editor styles | Title 24 bold, Heading 18 semibold, Subheading 15 semibold, Body 15 regular, Code block 13 SF Mono; body line height 1.25 and paragraph spacing 5 (lists 1.2 and 2, headings 12 before and 4 after) |
| Format bar | 36 pt high, 10 pt radius, surface colour, buttons 28 × 28 with 6 pt radius, active state in the accent at 14 % |
| Accent | the system accent colour; selection, links, the Start button, the "+" buttons |
| Folder colours | eight: red, orange, yellow, green, teal, blue, purple, pink, as system colours; default blue |
| Surfaces | `Theme.base` (window background) for the sidebar and the list column, `Theme.surface` (control background) for cards, the editor and the format bar; no 1 pt dividers between columns, the surface change marks the edge |
| Shadows | only the system window shadow and a soft `shadow(radius: 12, y: 4)` on the quick note field and toasts |
| Motion | 150 ms ease for selection, hover and toasts; 200 ms for the sidebar collapse; no bounce |

No hex values outside `Theme`. Both appearances checked in every preview.

## 4. Components

| Component | Rules |
|---|---|
| **Folder row** | Tinted icon, name, count. Selected: pill. Hover: a faint pill. Inline rename on double click or Rename. Inline delete confirmation replaces the count with "Yes · No" |
| **New folder** | A soft button at the bottom of the sidebar ("+ New folder"); a new row appears in edit mode with the name selected |
| **Note card** | As in section 2. Pinned cards come first with a small pin. A card never shows a type, a ticket, a tag or a status |
| **Search field** | Rounded (8), a magnifier, placeholder "Search", Esc clears. Results replace the cards in place with the matched line as the preview and the words in bold |
| **Format bar** | Left group: a paragraph style menu button showing the current style name (Title, Heading, Subheading, Body, Code block). Middle group: Bold, Italic, Strikethrough, and a colour menu (a highlighter icon with a bar in the current colour): Highlight in yellow, green, blue, pink, purple, Remove Highlight, then Text Colour in red, orange, green, blue, grey, Default Colour. `⇧⌘E` highlights in yellow, and again removes it. The same two menus are in the Format menu and at the top of the right-click menu of the text and of a table cell. Right group: Checklist, Bulleted list, Numbered list, Quote, Code block, Link, Image, Attach file, Table. Last group: Divider, Screenshot, Format JSON. When the bar is too narrow for all buttons, the last group moves into a "…" menu. Code block also works inside a code block and turns it back into paragraphs. Attach file adds any file as a link; ⌘-click the link to open it. A thin gap between groups. Active buttons tinted. Each button has a hint with the shortcut |
| **Editor text** | Formatted text, no marks. Checklist boxes are round and tick with the accent. Images are rounded (8) blocks with a thin border, 8 pt above and below. Highlights are a soft coloured background (weaker in dark mode), text colours are lighter in dark mode (ADR 0017). Links in the accent, open on `⌘`-click. A caret in a link shows a small bar under it: the address (or the note name) and Open, Edit, Copy, Remove; the right-click menu of a link has the same actions. `⌘K` opens the link window: Text and Link to (a web address or a note name, note names complete as you type), Remove Link, Cancel, Save. Code blocks show their language in the top-right corner ("Swift", "Plain text"); a click opens a menu of languages, and Swift, Objective-C, JSON, YAML, Shell, Diff and Log get Xcode-like colours. Raw blocks (Markdown the editor cannot show) in monospaced on a light tinted block |
| **Image** | An image in the text: 8 pt radius, a thin border, at most 360 pt high. Double-click opens Quick Look. On hover a round dark button (28 pt, a down arrow) sits 8 pt from the top right corner and saves a copy to Downloads; the toast says "Saved <file> to Downloads". Images smaller than 56 pt get no button. A small grip (16 pt) at the bottom right corner on hover changes the width by drag; the image keeps its aspect ratio. Right click: Quick Look, Open, Show in Finder, Copy Image, Save to Downloads, Size ▸ Small (240 pt), Medium (420), Large (640), Original Size. The width is stored in the file (ADR 0013) |
| **Table** | A block in the text (ADR 0009): 8 pt radius, a thin border, the header row semibold on a tinted background, cell padding 6 × 8, body text style. A click edits a cell in place. Enter goes to the cell below, `⇧Enter` starts a new line in the cell (ADR 0012), Tab and ⇧Tab to the next and previous cell; Tab on the last cell and Enter on the last row add a row. ↑ in the header row, ↓ in the last row, ← at the start of the first cell, → at the end of the last cell and Esc leave the table. The arrows also enter a table: ↓ from the line above goes to the header row in the column under the caret, ↑ from the line below goes to the last row, → at the end of the line before goes to the first cell, ← at the start of the line after goes to the end of the last cell. ⌘B, ⌘I, ⇧⌘X and ⌘K work in a cell. Several cells can be selected: Shift-click another cell, drag across cells, press Shift with an arrow at the edge of a cell's text, or press ⌘A twice. The selection is a tinted rectangle with an accent border. On it ⌘C copies the cells (tab-separated text and a table), ⌘X cuts, ⌘V pastes a block of cells from the top left cell and adds rows and columns when needed, Delete clears, ⌘B, ⌘I and ⇧⌘X toggle the style in every cell, typing replaces the first cell, an arrow or Esc goes back to editing one cell. The right-click menu on a selection starts with Clear Cells, and Align, Delete Rows and Delete Columns act on the whole selection. Find in Note (`⌥⌘F`) also searches the cells: a match in a cell is highlighted in place, and when the find bar closes on it that cell is being edited with the match selected. Replace works in cells too. On hover a thin "+" strip at the right edge adds a column and one at the bottom adds a row. On hover the row under the pointer shows a small grip at its left edge (not the header row) and the column shows one at its top edge. A click on a grip selects the row or the column and opens the table menu; dragging a grip moves the row or the column, and an accent line shows where it goes. Near the left edge, on the line between two rows, and near the top edge, on the line between two columns, a round accent "+" shows with an accent line along the border; a click adds a row or a column there. `⌥⌘↑` and `⌥⌘↓` move the row (or the selected rows), `⌥⌘←` and `⌥⌘→` move the column; the header row stays first. Right click on a cell: Add Row Above, Add Row Below, Add Column Left, Add Column Right, Move Row Up, Move Row Down, Move Column Left, Move Column Right, Align Left, Align Center, Align Right, Copy Table as Markdown, Copy Table as Text, Convert to Text, Delete Row, Delete Column, Delete Table ("Delete this table? Yes · No" when more than one cell has text). Columns take the width of their text; when the table is wider than the note text, columns shrink but not below 120 pt (or their text width), and the rest scrolls sideways inside the table: a trackpad swipe or Shift with the mouse wheel. A thin bar under the table shows the position on hover, and the cell being edited always scrolls into view. The Table button and `⌥⌘T` insert a table with a header and one row. With lines selected they turn those lines into a table instead: tabs split the columns, or `|` when every line has one, otherwise each line is one cell; the first line is the header. Convert to Text does the opposite: one line per row, a tab between the cells, images from cells on their own lines under the row. Since S7 a cell can hold images: a thumbnail 80 pt high with a 4 pt radius next to the text. Drop an image on a cell, paste it into a cell, or use the Image button or `⇧⌘S` while a cell is being edited. Double-click a thumbnail for Quick Look; Delete removes a selected thumbnail. Right click on a thumbnail adds Quick Look, Open, Show in Finder, Copy Image, Save to Downloads and Size ▸ Small (60 pt wide), Medium (120), Large (200), Default Size (80 pt high) above the other items |
| **Toast** | Bottom centre, 10 pt radius, surface colour with a soft shadow, 4 s, optional Undo button |
| **Empty folder** | A soft tinted circle with `square.and.pencil`, "Nothing here yet.", a "New note" accent button and the hint `⌘N` |
| **No results** | "No notes match.", a "Clear search" link |
| **Empty editor** | When no note is selected: a soft tinted circle with `note.text`, "Pick a note or press ⌘N." |
| **Inline confirmation** | "Delete? **Yes** · No" in place of the hover button for 5 s; Esc cancels |
| **"Changed on disk" banner** | A rounded strip above the text in the warning tint with "Keep mine" and "Take theirs". Never a sheet |

## 5. States

| State | What the user sees |
|---|---|
| Loading a large folder | Cards fill in as the scan runs; a thin progress line under the search field until it ends |
| Saving | "Saved" fades in at the top-right of the editor for one second |
| Conflict | The banner |
| Versions | The clock button next to the title opens a 640 pt popover: "Name this version" with Save Version, the versions on the left (a named version shows its name in bold with a bookmark, an agent's version has a purple Agent badge), and on the right the chosen version as "Changes since" (added lines green with +, removed lines red with −, struck through) or as "Text", with Restore. The list header of a folder has the same clock button for the Changes of the folder: the last 100 versions, each with what happened in plain words and the notes and files added, changed or removed; a click on a note opens it; "Clear History of <folder>…" at the bottom asks inline first. A file's "…" menu has Versions… with Quick Look and Restore per version. Settings → General has Clear History… under Back up to (ADR 0015) |
| Error from a command | A toast with one line and "Details", which opens the Activity list from Settings → General → Check-up |
| Trash | Cards with "Restore" and "Delete now" on hover; the footer line "Notes are removed from the Trash after 30 days." |

## 6. Interaction rules

- Hover reveals actions with opacity, never with a layout change.
- Every icon-only button has a hint and an accessibility label.
- Keyboard focus is visible; Tab order is sidebar → list → title → text.
- Esc goes one level back: hint → menu → search text. It never hides the window.
- Drag and drop: a card onto a folder moves it; a folder onto a folder moves it inside; an image onto the text inserts it at the drop point; a text file onto the list makes a note.
- Text never jumps: the format bar has a fixed height; the title grows to two lines at most.
- Right-click menus mirror the hover actions and the main menu.

## 7. Words in the interface

| In code and docs | In the interface |
|---|---|
| vault | Notes folder |
| space | Folder |
| capture | Quick note |
| attachment | Image or File |
| snapshot (history) | Version |
| index, reindex | (never shown) "Rebuild search" in Check-up |
| raw block | (never named) |
| trash | Trash |

Rules for text: a sentence, not a label with a colon, wherever there is room. Verbs on buttons ("Restore", "Keep mine"). No jargon. Error messages say what to do next.

## 8. Keyboard

| Keys | Action |
|---|---|
| `⌥⌘N` (global) | Show the Slate window on this desktop, or hide it when it is in front |
| `⌃⌥Space` (global) | Quick note |
| `⌘N` | New note in the current folder |
| `⇧⌘N` | New folder |
| `⌘F`, `⌃F` | In the note text (or its find bar): Find in Note. Anywhere else: search all notes |
| `⇧⌘F` | Search all notes, also from the note text |
| `⌘0` | Show or hide the folders |
| `⌥⌘0` | Show or hide the notes list |
| `⌘⇧O` | Open as window |
| `⌘1` … `⌘9` | Folder by position |
| `⌘↑` / `⌘↓` in the list | Previous and next note |
| `⌘⇧P` | Pin or unpin |
| `⌘⌫` in the list | Move to Trash (inline confirm) |
| `⇧⌘T`, `⇧⌘H`, `⇧⌘J`, `⇧⌘B`, `⇧⌘M` | Title, Heading, Subheading, Body, Code block |
| `⇧⌘L`, `⇧⌘7`, `⇧⌘9` | Checklist, Bulleted list, Numbered list |
| `⌘'` | Quote |
| `⌘B`, `⌘I`, `⌘⇧X` | Bold, Italic, Strikethrough |
| `⌘K` | Link |
| `⇧⌘I` | Image |
| `⇧⌘A` | Attach file |
| `⌃⇧↑`, `⌃⇧↓` | Add a caret on the line above or below (Edit menu). Typing, Backspace, Delete, Tab, ⇧Tab and the arrows then act at every caret; Tab indents a list item and puts a tab elsewhere; a deletion never joins two paragraphs. Esc, a click, Enter, paste, a format command or Undo leave one caret. While there are several carets Slate draws all of them, so they blink together; they do not work in table cells |
| `⌥⌘T` | Table |
| `⌥⌘←`, `⌥⌘→` | Collapse or expand the section of the caret (outside table cells) |
| `⇧⌥⌘←`, `⇧⌥⌘→` | Collapse or expand every section |
| `⌥⇧⌘J` | Format JSON (also a `curlybraces` button in the format bar, or in its "…" menu when the bar is narrow): the selection, or the code block at the caret, becomes a `json` code block with two-space indents. Text before and after the selection on the same line stays as its own paragraph. Text that is not JSON stays as it is, with the toast "The selection is not valid JSON" |
| `⌘,` | Settings |
| `Esc` | Back |

All of them appear in the main menu of the window.

## 9. Checklist for a screen

1. Looks right in light and dark (`#Preview` with both).
2. Rounded per section 3; no 1 pt divider lines between columns or rows; spacing from the scale.
3. One primary action; secondary actions on hover or in a menu; the same in the context menu.
4. Every icon button has a hint and an accessibility label.
5. Empty, loading, error and conflict states exist and use the words of section 7.
6. No modal dialog, no alert, no sheet.
7. Keyboard: reachable with Tab, shortcuts from section 8, Esc goes back.
8. Colours only through `Theme`, the accent and the folder colours.
9. Nothing on screen names a kind, a ticket, a tag, a status, the index, the vault or a snapshot. Exception (ADR 0014): inside a project, task folders and task notes show their status, ticket and branch.
