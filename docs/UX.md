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

Panel and window share one layout with three columns. The panel is what the menu bar icon opens; the window is the same content in a normal window ("Open as window", `⌘⇧O`). Both remember their size.

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

- Default 1040 × 680, minimum 820 × 520. Sidebar 200 pt (collapsible with `⌘0`, remembered), list 320 pt (draggable 260 to 420, remembered), editor the rest.
- **Sidebar**: the folders as rows with a tinted `folder.fill` icon in the folder's colour, the name, and the count in secondary text. Trash at the bottom of the folder list. "New folder" is a soft button at the very bottom. Selection is a rounded pill (section 3). Right click on a folder: Rename, Colour (eight dots), Icon, Move up, Move down, Delete folder (inline: "Delete 'Ideas'? Its 4 notes move to Notes. Yes · No"). Double click renames inline. Drag a note row onto a folder to move it.
- **List**: the folder name as a title (`.title2` semibold) with a round "+" button on the right; a rounded search field under it; then **note cards**: 12 pt padding, 10 pt radius, 6 pt gap, surface colour, a soft selection tint when selected, a slightly stronger tint on hover. Card content: title (one line, semibold), relative date on the right in secondary, a two-line preview in secondary, a small pin glyph at the top-right when pinned. Hover shows one round "…" button at the right edge of the card with: Pin, Move to ▸, Duplicate, Move to Trash. The same in the right-click menu.
- **Editor**: the title as a large field (24 pt bold, no border, placeholder "Title"), under it the **format bar** (section 4), then the text with 24 pt side padding and a maximum text width of 720 pt centred when the column is wider. Under the editor nothing: no footer, no chips. The saved state shows as a quiet "Saved" that fades in the top-right corner for a second after a save.
- **Quick note field** (`⌃⌥Space`): 520 pt wide, 14 pt radius, a soft shadow, the text at 15 pt, a bottom row with the folder menu on the left and "⏎ Save" on the right. Enter saves, `⌘Enter` saves and opens, `⇧Enter` is a new line, Esc closes and keeps the draft.
- **Settings**: one window, two pages in a sidebar, General (notes folder with Choose…, Open at login, Appearance, Text size, Back up to: a git address and "Back up now", Trash days) and Shortcuts (three recorders: Open Slate, Quick note, New note). A "Check-up" box at the bottom of General with three one-line checks (notes folder, versions, search) and "Rebuild search".
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
| Editor styles | Title 24 bold, Heading 18 semibold, Subheading 15 semibold, Body 15 regular, Monospaced 13 SF Mono; body line height 1.4; paragraph spacing 8 |
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
| **Format bar** | Left group: a paragraph style menu button showing the current style name (Title, Heading, Subheading, Body, Monospaced). Middle group: Bold, Italic, Strikethrough. Right group: Checklist, Bulleted list, Numbered list, Quote, Link, Image. A thin gap between groups. Active buttons tinted. Each button has a hint with the shortcut |
| **Editor text** | Formatted text, no marks. Checklist boxes are round and tick with the accent. Images are rounded (8) blocks with a thin border, 8 pt above and below. Links in the accent, open on `⌘`-click. Raw blocks (Markdown the editor cannot show) in monospaced on a light tinted block |
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
| Versions | The clock button next to the title lists versions with Restore; nothing else about history is visible except "Back up to" in Settings |
| Error from a command | A toast with one line and "Details", which opens the Activity list from Settings → General → Check-up |
| Trash | Cards with "Restore" and "Delete now" on hover; the footer line "Notes are removed from the Trash after 30 days." |

## 6. Interaction rules

- Hover reveals actions with opacity, never with a layout change.
- Every icon-only button has a hint and an accessibility label.
- Keyboard focus is visible; Tab order is sidebar → list → title → text.
- Esc goes one level back: hint → menu → search text → panel.
- Drag and drop: a card onto a folder moves it; an image onto the text inserts it at the drop point; a text file onto the list makes a note.
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
| `⌥⌘N` (global) | Open Slate (panel or window) |
| `⌃⌥Space` (global) | Quick note |
| `⌘N` | New note in the current folder |
| `⇧⌘N` | New folder |
| `⌘F` | Search |
| `⌘0` | Show or hide the sidebar |
| `⌘⇧O` | Open as window |
| `⌘1` … `⌘9` | Folder by position |
| `⌘↑` / `⌘↓` in the list | Previous and next note |
| `⌘⇧P` | Pin or unpin |
| `⌘⌫` in the list | Move to Trash (inline confirm) |
| `⇧⌘T`, `⇧⌘H`, `⇧⌘J`, `⇧⌘B`, `⇧⌘M` | Title, Heading, Subheading, Body, Monospaced |
| `⇧⌘L`, `⇧⌘7`, `⇧⌘9` | Checklist, Bulleted list, Numbered list |
| `⌘'` | Quote |
| `⌘B`, `⌘I`, `⌘⇧X` | Bold, Italic, Strikethrough |
| `⌘K` | Link |
| `⇧⌘I` | Image |
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
9. Nothing on screen names a kind, a ticket, a tag, a status, the index, the vault or a snapshot.
