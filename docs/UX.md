# UX rule book

The owner's requirement: **a high-quality interface that is simple to understand.** This file turns that into rules an agent can check. Every screen, row, banner and setting is compared with it before a milestone is called done.

Reference points: Apple Notes (list and editor, calm), Things 3 (keyboard, quick entry), Raycast (the palette). Slate copies their restraint, not their visuals.

---

## 1. Principles

1. **Native.** Standard AppKit and SwiftUI controls, the system font, system colours, SF Symbols, system list and toolbar metrics. The app follows the system appearance (light and dark). No custom skin, no custom fonts, no gradients, no shadows beyond what the system draws.
2. **Three visible concepts.** Folders, Notes, Tags. Everything else (note types, templates, smart views, actions, history, the CLI) is reached through a command, a menu or a setting, and a user who never finds it loses nothing.
3. **One obvious action per place.** A screen has one primary action in one place: the list has "New note", the editor has the text, the capture field has Enter. Secondary actions sit in a menu or appear on hover.
4. **Keyboard first, mouse complete.** Every action has a shortcut and a menu entry, and every action can also be done with the mouse. Nothing needs both.
5. **No modal dialogs.** No alerts, no sheets, no confirmation windows. Destructive actions confirm inline in the row ("Delete? Yes · No") and show a toast with Undo for five seconds.
6. **Instant.** A click or a keystroke shows its result at once; work that takes longer runs in the background with a small progress indicator and never blocks typing.
7. **Plain words.** UI text uses short, common words (section 7). No internal terms in the interface.
8. **Empty states teach.** An empty list or folder shows one sentence and the one shortcut that fills it.
9. **Forgiving.** Autosave, Undo everywhere (text, delete, move), a Trash, a history. The user never sees "Are you sure?".

## 2. Layout

### 2.1 Panel (from the menu bar)

```
┌───────────────────────────────────────────────────────────────────┐
│ [Folder ▾]   [ Search                         ]  [+ New]  [⧉] [⚙] │  header, 44 pt
├────────────────────────┬──────────────────────────────────────────┤
│ note list, 300 pt      │ note header: title, chips                │
│ rows 56 pt             │──────────────────────────────────────────│
│                        │ editor                                   │
│                        │                                          │
├────────────────────────┴──────────────────────────────────────────┤
│ 23 notes · saved just now · history 09:50          [Activity]     │  footer, 28 pt
└───────────────────────────────────────────────────────────────────┘
```

- Default 980 × 680, minimum 760 × 480. The list column is 300 pt by default, draggable between 240 and 400.
- The header is a toolbar: folder picker (menu button with the folder icon and name), the search field (expands to fill), New (a button with `+`), Open as window (icon), Settings (gear).
- The list is a standard `List` with `.sidebar`-like density off: plain rows, no section boxes. The selected row uses the accent colour at system opacity.
- The editor fills the right column: the note header is 56 pt (title in `.title3`, a row of chips under it), then the text.
- The footer is quiet: secondary colour, 11 pt, one line.

### 2.2 Window

The same as the panel plus a sidebar on the left (200 pt, collapsible with `⌘0`): Folders with counts, Tags, Saved searches, Trash. The window is a normal document-style window with the standard title bar and traffic lights.

### 2.3 Capture field

```
┌──────────────────────────────────────────────────────┐
│ Type a note…                                         │  text, 15 pt, grows to 6 lines
│                                                      │
│ Inbox ▾   Note ▾                 ⏎ Save   ⌘⏎ Open    │  footer, 28 pt
└──────────────────────────────────────────────────────┘
```

520 pt wide, centred on the active screen, 20 % down from the top. Rounded 12 pt, a thin border, a system shadow. Appears with a 120 ms fade, no scale. Esc closes it and keeps the draft.

### 2.4 Floating note (P1)

One note, no list, 420 × 520, a compact header with the title and a close button. Stays above other windows.

## 3. Spacing, type, colour

| Token | Value |
|---|---|
| Spacing scale | 4, 8, 12, 16, 24 |
| Row padding | 12 horizontal, 8 vertical |
| Section gap | 16 |
| Corner radius | 6 for chips and buttons, 8 for cards, 12 for the capture field |
| Title in the list | `.body` semibold, one line, truncates with `…` |
| Preview in the list | `.subheadline` secondary, two lines |
| Date in the list | `.caption` secondary, relative ("2 min", "Yesterday", "Oct 3") |
| Note title in the editor | `.title3` semibold, editable text field without a border |
| Editor prose | system font 14, line height 1.35 |
| Editor code | SF Mono 13, line height 1.2 |
| Chips | `.caption` medium on a tinted capsule, 22 pt high |
| Colours | `Theme` tokens mapped to system colours; the accent colour for selection and links; `Tint` for status: green done, blue active, orange review, grey todo, red dropped or destructive |

No hex values outside `Theme`. Both appearances are checked in every preview with `.preferredColorScheme`.

## 4. Components

| Component | Rules |
|---|---|
| **List row** | Title, two-line preview, relative date on the right of the title line, a row of small badges under the preview (type icon for non-plain notes, ticket chip, status dot, paperclip with a count, a checkbox icon with the open count). Pinned rows show a small pin at the top-right. Hover reveals two icon buttons on the right (Pin, More) without moving the text. Right click shows the same actions |
| **Note header** | The title field; under it chips: type (only when not a plain note), ticket (click opens; hover shows the URL), branch (click copies, toast "Branch copied"), MR (click opens), status (a menu button with the five states), tags (`#tag` chips, click filters the list). Chips wrap to a second line; the header grows |
| **Editor** | Marks visible in a lighter colour; headings larger; code on a tinted block with a language label at the top-right and a Copy button on hover; images under their line, 360 pt max; a checkbox glyph that toggles on click; links coloured, open on `⌘`-click. Caret and selection are the system ones |
| **Search field** | Standard rounded search field. Results replace the list in place with the snippet under the title; the match is bold. Esc clears |
| **Palette (P1)** | A single floating field 560 pt wide; results below in three groups with small grey headers; arrow keys; Enter |
| **Chips and tags** | Capsule, 22 pt, `.caption` medium, tinted background at 12 % opacity and the tint for the text; never cut, wrap instead |
| **Banner** | A one-line strip at the top of the editor in the warning tint: text on the left, two or three text buttons on the right ("Keep mine", "Take theirs", "Open both"). Never a sheet |
| **Toast** | Bottom centre of the panel, 4 s, one line, optional Undo button. One toast at a time |
| **Empty state** | Centred icon (secondary, 32 pt), one sentence, one shortcut hint. "No notes here yet. Press ⌘N." |
| **Inline confirmation** | The row's actions are replaced by "Delete? **Yes** · No" for 5 s; Esc cancels |
| **Settings** | One window with a sidebar of five items (General, Notes folder, Shortcuts, Links, History). Each page is a form with system controls. A "Doctor" row at the bottom of General with one-line checks and a Rebuild index button |
| **First launch** | One small window: "Where should Slate keep your notes?" with the default path, a Choose… button and a Start button. No tour, no account. After Start the Inbox opens with one welcome note that lists three shortcuts |

## 5. States

| State | What the user sees |
|---|---|
| Loading a large vault | The list shows what is already indexed; a thin progress bar under the header, "Indexing 3,120 of 10,000" in the footer |
| Saving | Footer "saved just now" after each save; never a spinner for a save |
| Conflict (file changed on disk) | The banner (section 4); the text stays editable |
| History | Footer "history 09:50"; when a remote is set and the push failed, "push failed" in the warning tint; click opens Activity |
| Offline | Nothing changes except link titles are not fetched and Jira details show the key only |
| Error from a command (git, screencapture, an action) | One line in Activity with the command and the message; a toast "Screenshot failed · Details" when the user started it |
| Trash | A list like any folder with "Restore" and "Delete now" on hover and a footer "Items are removed after 30 days" |

## 6. Interaction rules

- Hover reveals actions with opacity, never with a layout change.
- Every icon-only button has a tooltip-like hint (DevHub's `.hint`, 0.5 s) and an accessibility label.
- Keyboard focus is visible on every control; Tab order is list → editor title → editor body.
- Esc goes one level back: hint → popover → search text → panel.
- Drag and drop: a note row onto a folder in the sidebar moves it; a file onto the editor attaches it; an image onto the list creates a note with the image.
- Animations: 120 to 180 ms fades and moves with the system curve. No bounce, no spring on lists, no parallax.
- Text never jumps: a chip row that wraps grows downward; a banner pushes the editor down with an animation.
- Right-click menus mirror the hover actions and the main menu.

## 7. Words in the interface

Code uses the vocabulary of `STORAGE-FORMAT.md`; the interface uses plain words. The mapping is fixed:

| In code and docs | In the interface |
|---|---|
| vault | Notes folder |
| space | Folder |
| note type | Kind (shown only in the New menu: Note, Task, Daily, Snippet, Meeting) |
| smart view | Saved search |
| capture | Quick note |
| attachment | Image or File |
| snapshot (history) | Version |
| index, reindex | (never shown) "Rebuild search" in Doctor |
| wikilink | Link to a note |
| frontmatter, header | Details |
| trash | Trash |
| ticket | Ticket (configurable label in Settings → Links, default "Ticket") |
| merge request | Merge request (label configurable, default "MR") |
| status: todo, active, review, done, dropped | To do, In progress, In review, Done, Dropped |

Rules for text: a sentence, not a label with a colon, wherever there is room ("No notes here yet." not "Notes: 0"). Verbs on buttons ("Restore", "Keep mine"). No jargon ("index", "frontmatter", "vault", "FTS"). Error messages say what to do next.

## 8. Keyboard

The map in `SPEC.md` section 10 is the contract. Every item appears in the main menu of the window, so the shortcuts are visible and changeable in System Settings → Keyboard → App Shortcuts.

## 9. Checklist for a screen

Before a screen or a row is called done:

1. Looks right in light and dark (`#Preview` with both).
2. Stretches: no fixed width for the whole row or screen; long text truncates or wraps on purpose.
3. One primary action; secondary actions on hover or in a menu; the same actions in the context menu.
4. Every icon button has a hint and an accessibility label.
5. Empty, loading, error and conflict states exist and use the words of section 7.
6. No modal dialog, no alert, no sheet.
7. Keyboard: reachable with Tab, has shortcuts from the map, Esc goes back.
8. Colours only through `Theme` and `Tint`; spacing from the scale.
9. Nothing in the text names the index, the vault, a space or a snapshot.
