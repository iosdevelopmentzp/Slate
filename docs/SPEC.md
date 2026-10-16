# Slate — specification

Working name **Slate**. To rename, replace `Slate`, `slate` and `SLATE_` in this folder.

Written for an AI coding agent and for the owner. The agent reads this file, `STORAGE-FORMAT.md`, `ARCHITECTURE.md` and `ROADMAP.md`, then builds milestone by milestone.

---

## 0. How to read this document

1. **The result is a working app** that replaces Apple Notes for daily work. Not a prototype.
2. **Priorities.** **P0** must work at the end of the first build. **P1** should work. **P2** is done when time remains. An unfinished item goes to `docs/STATUS.md` under "Next steps" with what is missing.
3. **The agent decides small things.** When the spec leaves a choice open, pick the simplest option that keeps the layers clean, write the decision into `docs/STATUS.md` and continue. Section 13 lists the decisions already taken with the owner.
4. **The storage format is a contract.** Other tools (Obsidian, the CLI, scripts, Claude Code) read and write the same files. `STORAGE-FORMAT.md` changes only with a new ADR.
5. **Feature IDs** (`A1`, `D3`, …) are stable. Commits, `STATUS.md` and tests refer to them.
6. **Plain English everywhere.** Documentation, UI text, hints, commit messages: short sentences, common words, no idioms.
7. **Nothing project-specific.** The app and the repository stay anonymous: no real company, product, host, ticket prefix or person (principle 10, ADR 0006). Examples use `ABC-123` and `example.com` hosts.
8. **UX rules.** `UX.md` is the rule book for every screen: native macOS look, three visible concepts, keyboard first, no modal dialogs. Read it before any view.

## 0.9 Scope revision 1: v1 is notes in folders (2026-10-16)

The owner tried the full build (M0 to M7) and asked for a simpler first version. ADR 0007 fixes the scope, ADR 0008 changes the editor, `UX.md` revision 2 changes the look. This section wins over the rest of this document until a later revision widens the scope again.

| In v1 | Parked (code stays in Domain and Data, nothing visible) |
|---|---|
| Folders: create, rename, delete, reorder, colour, icon (C1 without kinds) | Note kinds, templates, Insert Template (C2, C11) |
| Notes: new, edit, pin, move, duplicate, Trash with restore and 30-day purge (C5, C7, C8) | Tasks, tickets, branches, merge requests, status, `⌘⇧D` (C3, G1, G5, G7) |
| Rich text editor with a format bar: styles, bold, italic, strikethrough, lists, checklist, quote, link, image, divider; images in the text (ADR 0008) | Markdown marks on screen, code highlighting, Paste as code bar (D1, D3 parts) |
| Images and files by paste, drag and the Image button; screenshot `⌘⇧S` (B4, D4) | Tags, `#` completion, tag chips (C4) |
| Search over titles and text in the current folder or all notes (E1 without filters) | Search filters, saved searches, Open TODOs, the palette (E2, C9, E3, A7) |
| Quick note from the hotkey into the quick-note folder (B1) | Today, daily notes, `⌥Enter`, `⌘[` `⌘]` (B3, C10) |
| Panel and window with the same three columns; `⌘0` sidebar (A2, A3) | Float on Top, note windows (A6) |
| Autosave, journal, "Changed on disk" banner, versions with Restore (D6, F2, F5 quiet) | History page in Settings, push state in a footer, Activity in a footer (shown only from Check-up) |
| Settings: General and Shortcuts only (H1 reduced, H4 as one "Back up to" field) | Links page, Jira token, link patterns and chips (H2, H5, G1) |
| `slate` CLI, `slate://`, Services entry keep working without UI (G2, G3, B6) | Actions, export menu, Copy for Slack (G4, F6) |
| Welcome note on first launch; one default folder `Notes` | Six default folders, `_templates/`, `.slate/types/`, `views.json`, `links.json`, `actions/` |

Scenarios for v1: S2 without the chips, S5, S6 without filters, S11, S12. The others wait with their features.

---

## 1. What Slate is

A personal macOS menu bar app for notes. One hotkey opens a panel with a note list and an editor. A second hotkey opens a small capture field. Notes are Markdown files in a folder the user owns. A SQLite index makes search instant. A task note knows its ticket, branch and merge request. A CLI and a URL scheme let other tools write notes.

| | Apple Notes | Obsidian | Slate |
|---|---|---|---|
| Open from the menu bar in under 100 ms | yes | no | **yes** |
| Quick capture without opening the app | no | no | **yes** |
| Markdown, code blocks with highlighting | no | yes | **yes** |
| Plain files you own, readable by other tools | no | yes | **yes** |
| Note tied to a ticket, branch, merge request | no | plugin | **built in** |
| Screenshot into the note in one keystroke | partial | no | **yes** |
| Checklists and open-TODO view across notes | partial | plugin | **built in** |
| Scriptable (CLI, URL scheme, actions) | no | plugin | **built in** |
| Sync | iCloud | paid or iCloud | **iCloud Drive folder** |
| History of a note | no | paid | **git, out of the vault** |
| Rich text, drawings, collaboration | yes | no | **no (not a goal)** |

### 1.1 Who uses it

One person: an iOS developer. tickets in an issue tracker (keys like `ABC-123`), merge requests on a git host, one git worktree per ticket, Slack, Claude Code sessions, simulators. The same person already runs **DevHub** (menu bar hub for git, worktrees, simulators, builds) and **Verba** (menu bar text helper). Slate is the third tool of that family and shares their code conventions (`ARCHITECTURE.md`).

### 1.2 Why not an existing app

- **Apple Notes**: no Markdown, no code blocks, no plain files, no ticket metadata, no scripting. Export is hard.
- **Obsidian**: plain files and plugins, but Electron, slow to open, no menu bar capture, task features need plugins. It stays useful as a second editor for the same vault, so Slate keeps the vault Obsidian-compatible.
- **Bear, Craft, Notion**: closed formats or cloud accounts, no developer metadata.

### 1.3 Principles

1. **Capture first.** Saving a thought takes zero decisions: hotkey, type, Enter. It lands in Inbox. Sorting comes later.
2. **Files are the database.** Markdown with a YAML header in a folder. The app is a view over the folder. Any editor can open it. The search index is derived and can be deleted at any time (ADR 0001).
3. **Fast.** Panel open under 100 ms. Typing with no visible delay on a 5,000-line note. Search under 50 ms over 10,000 notes. Numbers in section 11.
4. **Keyboard first.** Every action has a shortcut. `⌘K` finds notes and commands.
5. **Made for a developer.** Code fences with highlighting, monospace where it matters, ticket and branch and merge request as fields, paste a stack trace as code, screenshot from the simulator in one keystroke.
6. **Extensible without a fork.** Templates, note types, link patterns, actions (scripts), a CLI, a URL scheme. Inside the code: ports and use cases, so a new source of data or a new command is one module away (`ARCHITECTURE.md` section 10).
7. **Nothing is lost.** Autosave, a trash with retention, git history, an optional remote. A conflict is shown, never resolved in silence.
8. **Degrade, do not break.** No git: no history. No remote: local history only. No network: everything works except link titles, Jira details and the push.
9. **Apple Notes parity where it matters.** Instant new note, list with preview, pin, folders, search, images, checklists, drag and drop. No parity for rich text, handwriting or sharing.
10. **The app knows no project.** No company, product, host, ticket prefix, branch pattern or person appears in Swift, in resources, in defaults or in the repository. Such facts come only from Settings and from `.slate/` files in the user's vault (ADR 0006). Examples in these documents use `ABC-123`, `example.atlassian.net` and `gitlab.example.com`.

### 1.4 Non-goals for v1

- A rich text editor (WYSIWYG), tables editor, drawing, math.
- Collaboration, sharing, multi-user, a web app.
- A custom sync server. End-to-end encryption.
- An iOS app (owner's decision, Q2). The storage choice keeps the door open.
- App Store, sandbox, notarization. Ad-hoc signing only (ADR 0003).
- A plugin runtime inside the app (JavaScript plugins). Extension goes through files, the CLI and scripts.
- Replacing Jira, Reminders or Calendar.

---

## 2. Daily scenarios

Each scenario is a test the finished app must pass.

| # | Trigger | Steps | Result |
|---|---|---|---|
| S1 | A ticket arrives: `ABC-2324 Profile screen leaks memory` | `⌥⌘N` opens the panel. `⌘⇧T` New task. Paste `ABC-2324 Profile screen leaks memory`, Enter | A task note in `Tasks` from the task template. Header chips: ticket (opens Jira), suggested branch `feature/ABC-2324-profile-screen-leaks-memory` (click copies), status `todo`. Cursor in the first section |
| S2 | Working on the task | Paste a Slack link, a Figma link, a merge request URL. Press `⌘⇧S`, drag a region over the simulator | Links render as chips with a title when online. The screenshot file lands in `_attachments/` and shows inline under the cursor |
| S3 | Paste a stack trace | `⌘⇧V` | A fenced code block with the trace, monospace, no smart quotes |
| S4 | Standup at 10:00 | `⌥⌘T` opens Today. `⌘K`, type `open todos` | Today's note shows yesterday's unchecked items under "Carried over". The Open TODOs view lists every unchecked item across the vault with its note. "Copy as Slack" copies a message in Slack format |
| S5 | A thought while in Xcode | `⌃⌥Space`, type two lines, Enter | A new note in `Inbox`, title from the first line, created now. Xcode keeps the focus; the field closes |
| S6 | Find something from two months ago | `⌘K`, type `retain cycle audio engine` | Results in under 50 ms with the matching line as a snippet. Enter opens the note at the match. `⌘Enter` opens it in a window |
| S7 | The task is merged | `⌘⇧D` in the task note | Status `done`, the note leaves the Active group of `Tasks` and stays in search |
| S8 | Need the `xcodebuild` destination flag again | `⌘K`, `type:snippet destination` | The snippet note opens; the copy button on the code block copies it |
| S9 | A meeting | `⌘N` with the `meeting` type | Template with Attendees, Decisions, Actions. Items under Actions are checkboxes and appear in Open TODOs |
| S10 | Claude Code finishes an investigation | The session runs `slate append --ticket ABC-2324 --section Findings "…"` | The text appears in the task note within one second, also when the note is open in the editor |
| S11 | The same note was edited by another tool (Obsidian, Claude Code, a script) | The file changes on disk while the note is open with local edits | A banner: "Changed on disk". Keep mine, Take theirs, or Open both. Nothing is overwritten in silence |
| S12 | Restore last week's version of a note | Note menu, History | A list of git snapshots for this file; Restore writes that version as the current content and keeps the old one as a snapshot |

---

## 3. Shell of the app

### 3.1 Menu bar item

- Status item with a template SF Symbol (`note.text` or similar). Left click toggles the panel. Right click opens a menu: New Note, New Task, Quick Capture, Today, Open Window, Settings, Quit.
- **P2**: a small badge in the icon with the count of open TODOs in Today. Off by default.

### 3.2 Panel (P0)

- Borderless `NSPanel` owned by the app, as in DevHub (`panel-window` skill, DevHub seed SPEC section 8.1). Not `MenuBarExtra(.window)`: it resets the position and cannot be moved.
- Default 980 × 680 points, minimum 760 × 480, resizable, movable, position remembered per screen. Appears at once with the last state; refreshes in the background.
- Two columns: **note list** (left, 280 to 360 points, resizable) and **editor** (right). The spaces sidebar is a popover from the header's space picker; the full sidebar lives in the window (3.3).
- Header: space picker (`⌘⇧[` / `⌘⇧]` previous and next space), search field (`⌘F` focuses, Esc clears), New note (`⌘N`), New task (`⌘⇧T`), Open as window, Settings.
- Footer: note count, history status (last snapshot time, push state when a remote is set), an Activity button that opens the activity log.
- A click outside closes the panel; so does switching to another app. Esc with an empty search field and no popover closes it. Unsaved text is saved before the panel closes.
- Follows the system appearance (light and dark). Colours come only from semantic `Theme` tokens mapped to system colours, so dark mode costs nothing.

### 3.3 Window (P0)

- A regular `NSWindow` for long sessions: "Open as window" in the header, `⌘⇧O`, or the status menu. Three columns: **Spaces sidebar** (spaces, tags, smart views, Trash) | note list | editor. `⌘0` hides the sidebar.
- More than one window is allowed (`⌘⇧N` opens the current note in a new window). The window frame is remembered. The panel and the windows show the same stores; a change in one is visible in the others at once.
- Window and panel share one `RootView` with an environment flag, like DevHub's pinned window.

### 3.4 Capture field (P0)

- A small floating panel, 520 × about 150 points, centred on the active screen: a multi-line text field, a space chip (default from Settings, click to change), a type chip (`note` by default, `task` when the text starts with a ticket key), a hint line with the shortcuts.
- Opens from a global hotkey (default `⌃⌥Space`) or the status menu. **Must not activate the app or steal the focus of the source app** beyond the field itself (Verba's `ui-panel` rule has the verified way). Esc closes and keeps the draft until the next open.
- Enter saves and closes. `⌘Enter` saves and opens the note in the panel. `⌥Enter` appends the text to Today as a timestamped bullet. `⇧Enter` inserts a line break.
- Accepts a pasted image, a pasted file or a URL on its own. The handling is the same as in the editor (5.5).

### 3.5 Floating note (P1)

- "Float on top" on a note opens it in a compact always-on-top window (one note, no list, 420 × 520 by default). For a checklist next to Xcode. Several floating notes are allowed.

### 3.6 Command palette (P1)

- `⌘K` from any window. One field, three groups: **Notes** (title match, then content match with a snippet), **Commands** (every menu action, templates, actions from `.slate/actions/`), **Recent**. Filters from section 6.1 work in the same field. Arrow keys and Enter; `⌘Enter` opens in a window; `⌘C` on a result copies the note path.
- In P0 the header search field covers the Notes part; the palette adds commands and recents.

---

## 4. Feature catalogue

Acceptance is what the agent and the owner check by hand.

### A. Shell and access

| ID | P | Feature | Acceptance |
|---|---|---|---|
| A1 | P0 | Status item, left click toggles the panel, right click menu | The icon shows in every space; the menu has the seven items of 3.1 |
| A2 | P0 | Panel per 3.2 | Opens under 100 ms warm, remembers size and position, closes on outside click |
| A3 | P0 | Window per 3.3 | Sidebar, list, editor; `⌘0` hides the sidebar; frame remembered |
| A4 | P0 | Global hotkeys: toggle panel `⌥⌘N`, capture `⌃⌥Space`, Today `⌥⌘T`, all changeable in Settings with a recorder | Each works when another app is frontmost; no Accessibility permission needed |
| A5 | P0 | Launch at login (`SMAppService`) | Toggle in Settings; `requiresApproval` shows a hint with the System Settings path |
| A6 | P1 | Floating note window per 3.5 | Stays above Xcode; checkbox clicks work; closes with `⌘W` |
| A7 | P1 | Command palette per 3.6 | Every menu command is reachable from `⌘K` |
| A8 | P2 | Dock icon toggle, open-TODO badge on the status icon | Off by default |

### B. Capture

| ID | P | Feature | Acceptance |
|---|---|---|---|
| B1 | P0 | Capture field per 3.4 | S5 passes; the source app keeps the focus |
| B2 | P0 | New note anywhere: `⌘N` in the current space, cursor in the title; `⌘⇧T` new task with the ticket prompt | A note exists on disk within one second of the first keystroke in the body |
| B3 | P0 | Append to Today from the capture field (`⌥Enter`) | A bullet `- 10:42 text` under today's "Log" section; the note is created when missing |
| B4 | P0 | Screenshot into the note: `⌘⇧S` region, `⌘⇧W` window, through `screencapture -i` / `-iw` to a file in `_attachments/`; the Markdown image is inserted at the cursor | S2 passes; the panel hides during the capture and returns after |
| B5 | P0 | Paste handling per 5.5: image, file, URL, "paste as code" `⌘⇧V` | Each kind produces the Markdown described in 5.5 |
| B6 | P1 | macOS Services menu entry "Add to Slate" for selected text (`NSServices` in `Info.plist`, no extension target) | Select text in Safari, Services → Add to Slate, a note appears in Inbox |
| B7 | P1 | URL scheme `slate://` per 8.2 | `open "slate://new?title=Hi"` creates a note and shows it |
| B8 | P2 | A global hotkey "screenshot to Today" that works while another app is frontmost | |
| B9 | P2 | Share extension for Safari | Only if B6 proves not enough |

### C. Notes and organisation

| ID | P | Feature | Acceptance |
|---|---|---|---|
| C1 | P0 | Spaces are top-level folders of the vault. Default set: `Inbox`, `Tasks`, `Notes`, `Daily`, `Snippets`, `Archive`. Create, rename, reorder, pick an icon; order and icon in `.slate/spaces.json` | A folder created in Finder shows as a space after the next watcher event |
| C2 | P0 | Note types `note`, `task`, `daily`, `snippet`, `meeting`: a type sets the template, the header fields, the list row badges and the default space | Each type creates from its template in `_templates/` |
| C3 | P0 | Task notes: fields `ticket`, `branch`, `mr`, `status` (`todo`, `active`, `review`, `done`, `dropped`). Header chips: ticket opens the tracker URL, branch copies, mr opens. The `Tasks` list groups by status: Active (`active`, `review`), Todo, Done (collapsed). `⌘⇧D` sets `done` | S1 and S7 pass |
| C4 | P0 | Tags: `#tag` in the body and `tags:` in the header, merged. Tag list in the sidebar with counts. `tag:` filter in search | Typing `#` offers existing tags |
| C5 | P0 | Pin (top of its list), Archive (moves to `Archive`), Trash (moves to `.trash/`, restore, auto-empty after 30 days) | Trash shows the original space; restore puts the file back |
| C6 | P0 | Wikilinks `[[Title]]` and `[[Title\|alias]]`: autocomplete after `[[`, `⌘`-click follows, a link to a missing note creates it on click; renaming a note rewrites its links in other notes | S-rename: rename a note that three notes link to, all three links update |
| C7 | P0 | Note list rows: title, two-line preview without Markdown marks, relative date, badges (type icon, ticket, status, attachment count, open TODO count). Sort by updated, created or title; pinned first. The header search filters the current list | A 2,000-note space scrolls without hitches |
| C8 | P0 | Move between spaces (drag to the space picker or sidebar, `⌘⇧M` picker), Duplicate, Rename (title edit renames the file) | Links by title keep working after a move |
| C9 | P1 | Smart views: saved queries in `.slate/views.json`. Built in: Open TODOs, Active tasks, Changed this week, Untagged, Conflicts | A view is a query string from 6.1 plus a name and an icon |
| C10 | P1 | Daily notes: `Daily/YYYY-MM-DD.md` from the daily template on first use each day; unchecked items from the latest earlier daily note are copied under "Carried over"; `⌥⌘T` opens Today; `⌘[` and `⌘]` go to the previous and next day | S4 passes |
| C11 | P1 | Templates with placeholders `{{date}}`, `{{time}}`, `{{title}}`, `{{ticket}}`, `{{branch}}`, `{{cursor}}`; "Insert template" command | A user template in `_templates/` appears in the palette |
| C12 | P2 | Merge an Inbox note into another note; split a note by heading; note aliases | |

### D. Editor

Details in section 5.

| ID | P | Feature | Acceptance |
|---|---|---|---|
| D1 | P0 | Markdown source editing with styled marks in place (5.1) | Headings, emphasis, inline code, links, quotes, lists look styled while the marks stay visible |
| D2 | P0 | Lists and checkboxes (5.2) | Enter continues a list, Tab indents, click toggles a checkbox, `⌘⇧L` toggles the current line |
| D3 | P0 | Code fences with language highlighting and a copy button (5.3) | Swift, Objective-C, JSON, YAML, shell, diff, log, plain |
| D4 | P0 | Inline images and file chips (5.4) | An image shows under its line at a capped height; double-click opens Quick Look |
| D5 | P0 | Links and link patterns (5.6) | `ABC-2324` renders as a chip; `⌘`-click opens Jira; a plain click places the cursor |
| D6 | P0 | Autosave and crash safety (5.7) | Kill the app mid-typing; the text is there after relaunch |
| D7 | P0 | Title field above the body; the file name follows the title (STORAGE-FORMAT section 3) | Rename in the title field renames the file and rewrites links |
| D8 | P1 | Outline popover, heading fold, find in note `⌘F` inside the editor, find and replace | |
| D9 | P1 | Editing habits from code editors: `⌥↑`/`⌥↓` move line, `⌘D` duplicate line, `⌘/` toggle a comment inside a code fence, auto-close of backticks and fences | |
| D10 | P2 | Live preview mode that hides marks on lines without the cursor | Only after D1 is stable |
| D11 | P2 | Tables as aligned monospace with a "Format table" command | |

### E. Search

| ID | P | Feature | Acceptance |
|---|---|---|---|
| E1 | P0 | Header search: title match at once (in memory), content match through the FTS index, results with a highlighted snippet | S6 passes |
| E2 | P0 | Filters in the query (6.1): `tag:`, `space:`, `type:`, `ticket:`, `status:`, `is:todo`, `is:pinned`, `has:image` | `type:task status:active` lists the active tasks |
| E3 | P1 | Open TODOs view: every unchecked checkbox across the vault, with the note title, grouped by note or by ticket; click toggles the item in its file | A toggle in the view changes the file and the open editor |
| E4 | P1 | Recent and frequent notes in the empty palette | |
| E5 | P2 | Core Spotlight indexing so a note opens from Spotlight | |

### F. Sync, backup and safety

| ID | P | Feature | Acceptance |
|---|---|---|---|
| F1 | P0 | Vault folder chosen on first launch; default `~/Documents/Slate`. Any folder works, including one inside iCloud Drive or another synced folder. Index outside the vault | Changing the vault re-indexes and keeps the old index untouched |
| F2 | P0 | File coordination and a vault watcher: external edits (Obsidian, Claude Code, iCloud) re-index and reload an open note that has no local edits; both changed means a conflict banner | S11 passes |
| F3 | P2 | Synced-folder specifics, only when the vault is inside iCloud Drive: not-yet-downloaded files show as "in cloud" and download on open; conflict versions (`NSFileVersion`) appear in the Conflicts view with Keep current, Keep other, Keep both | A file set to "Remove download" in Finder still shows in the list |
| F4 | P0 | Trash with 30-day retention and restore (C5) | |
| F5 | P0 | History and backup: git snapshots with the repository **outside the vault** (`--git-dir` in Application Support, `--work-tree` the vault), every 10 minutes when dirty and on quit; optional push to a remote; per-note history with restore (S12) | No `.git` folder appears in the vault |
| F6 | P1 | Export: copy as Markdown, copy as Slack format, save as HTML, print to PDF | "Copy as Slack" turns `**bold**` into `*bold*`, keeps code fences, turns `- ` into `•` |
| F7 | P2 | Import from Apple Notes (export through AppleScript to HTML, convert to Markdown, images to attachments) | |

### G. Developer integrations and extension points

Details in section 8.

| ID | P | Feature | Acceptance |
|---|---|---|---|
| G1 | P0 | Link patterns in `.slate/links.json`: regex to URL template and label. Defaults: Jira key, GitLab merge request `!123`, GitLab issue `#123` | Editing the file changes the chips without a restart |
| G2 | P1 | URL scheme `slate://` (8.2) | |
| G3 | P1 | CLI `slate` (8.3) | S10 passes |
| G4 | P1 | Actions: `.slate/actions/*.json` run a script with the note's path, ticket and branch in the environment; output goes to the activity log or is appended to the note | "Open worktree in Terminal" works from a task note |
| G5 | P1 | Jira details for a task note (read-only): title, status, assignee, through an API token in the Keychain; off until a token is set | Offline shows the key only |
| G6 | P2 | "Ask Claude" on a note through the local `claude -p` CLI with prompts from `.slate/prompts/*.md` (summarise, standup from Today, extract TODOs); no API key in the app | |
| G7 | P2 | Merge request status chip through `glab api` (no token stored, as DevHub does) | |
| G8 | P2 | "Paste as clean log": strip Xcode console prefixes (date, process, pid) from pasted lines | |

### H. Settings

| ID | P | Setting |
|---|---|---|
| H1 | P0 | Vault folder (change re-indexes), hotkeys, launch at login, default space for capture, editor font and size, appearance (system, light, dark), trash retention days |
| H2 | P0 | Tracker: Jira base URL and ticket key pattern; GitLab base URL and project path (used by the default link patterns and the branch suggestion pattern `feature/{{ticket}}-{{slug}}`) |
| H3 | P1 | Daily notes: on or off, carry-over on or off, template name |
| H4 | P1 | History: on or off, interval, remote URL, push on quit |
| H5 | P1 | Jira token (Keychain), test button |
| H6 | P0 | Doctor: vault reachable, git available, remote reachable, last snapshot and push, index size and last rebuild, `screencapture` available, hotkey conflicts; Rebuild index button |

---

## 5. Editor

The editor is a **thin Markdown text view**, not a rich text editor (ADR 0005). The value of Slate is in capture, organisation, search and integrations. The editor must be fast and predictable; it does not hide the Markdown in v1.

### 5.1 Styling in place (D1)

- `NSTextView` on TextKit 2, wrapped for SwiftUI, in its own module `SlateEditor` (`ARCHITECTURE.md` section 6). Attributes are applied to the source text; the source never changes because of styling.
- Styled: `#` headings (three sizes, bold), `**bold**`, `*italic*`, `` `inline code` `` (monospace on a tinted background), links and wikilinks (accent colour), `>` quotes (tinted bar), lists (hanging indent), horizontal rules, fenced code (5.3). Marks like `#`, `**` and `` ` `` stay visible in a lighter colour.
- **Incremental.** A keystroke restyles only the paragraphs that changed plus any code fence that contains them. Never a full re-parse per keystroke. The highlighter is line based and knows fence state; the full Markdown parser (`swift-markdown`) is used for the index, the outline and export, not for typing.
- Font: the system font for prose, SF Mono for code; both sizes from Settings. Line height 1.35 for prose.

### 5.2 Lists and checkboxes (D2)

- Enter after a list item continues the list with the same marker; Enter on an empty item removes the marker. Tab and `⇧Tab` indent and outdent the item. Ordered lists renumber on Enter.
- `- [ ]` and `- [x]` render a checkbox glyph before the text; a click toggles it and writes `x` or a space back into the source. `⌘⇧L` toggles the current line between plain item, open box and checked box. A checked item is drawn in a secondary colour.
- Smart list continuation also works inside quotes.

### 5.3 Code fences (D3)

- ```` ``` ```` with an optional language. The block has a tinted background, monospace font, a language label and a Copy button on hover in the top right corner. Long lines wrap at the editor width with a hanging indent (an `NSTextView` wraps the whole document; per-block horizontal scrolling is not possible and is not wanted in v1).
- Highlighting by a small, own, regex-based highlighter per language: keywords, strings, comments, numbers, types. Languages in v1: `swift`, `objc`, `json`, `yaml`, `bash` (also `zsh`, `sh`), `diff`, `log` (timestamps and levels), `plain`. Unknown language falls back to `plain`. No JavaScript engine, no `highlight.js`: start time and typing latency matter more than perfect colours.
- Tab inside a fence inserts four spaces. Paste inside a fence keeps indentation and never converts quotes.

### 5.4 Attachments (D4)

- `![alt](../_attachments/file.png)` renders the image under its line, scaled to the editor width and capped at 360 points high; double-click opens Quick Look; a context menu offers Open, Reveal in Finder, Copy image, Remove (asks inline, deletes the reference and moves the file to Trash when no other note references it).
- Any other file link to `_attachments/` renders as a chip with an icon and the file name; double-click opens it; drag out copies it to Finder.
- Attachment files are stored and named per `STORAGE-FORMAT.md` section 5.

### 5.5 Paste rules (B5)

| Pasted | Result |
|---|---|
| Image | File written to `_attachments/`, `![](…)` inserted |
| One or more files | Copied to `_attachments/`, one link chip per file; an image file becomes an image |
| A URL on its own line | `[Title](url)` after the title is fetched (2 s timeout, P1); until then and offline the plain URL |
| Text with three or more lines that looks like code or a log (indentation, braces, `at `, timestamps, `Thread 0 Crashed`) | A bar above the editor: "Paste as code?" with the detected language; Enter accepts, Esc keeps plain |
| `⌘⇧V` | Always a code fence; language from the detection, `plain` when unsure |
| Rich text | Plain text; the bold and links are converted to Markdown when the pasteboard has HTML |

### 5.6 Links (D5)

- URLs are detected and styled. Wikilinks per C6. Link patterns from `.slate/links.json` render matching text as a chip with a label and an icon; the source text stays as typed (`ABC-2324`).
- `⌘`-click or `⌘Enter` with the cursor inside a link opens it. A plain click only moves the cursor. Hover shows the target after 0.5 s.
- Pasting a URL whose host matches a pattern (a Jira issue URL, a merge request URL) offers to insert the short form instead (`ABC-2324`, `!1234`).

### 5.7 Autosave and safety (D6)

- Save after 500 ms of no typing, on focus loss, on panel close, on window close and on quit. Atomic write through file coordination (`STORAGE-FORMAT.md` section 8). `updated` is refreshed only when the body or the header changed.
- A journal file in Application Support keeps the current unsaved text of each open note; on relaunch after a crash the journal wins when it is newer than the file and the user confirms.
- Before a save, the on-disk content hash is compared with the hash loaded. A mismatch that is not our own write is a conflict (F2): the save is held, the banner appears, the text stays in the journal.

---

## 6. Search

### 6.1 Query language

Free words match title, body, tags and ticket. Words are ANDed. A quoted phrase matches as a phrase. Filters:

| Filter | Meaning |
|---|---|
| `tag:audio` | note has the tag |
| `space:Tasks` | note is in the space |
| `type:task` | note type |
| `ticket:ABC-2324` | header field |
| `status:active` | header field (tasks) |
| `is:todo` | note has at least one open checkbox |
| `is:pinned`, `is:trashed`, `is:conflict` | state |
| `has:image`, `has:code`, `has:link` | content kind |
| `before:2026-10-01`, `after:2026-09-01` | `updated` range (P1) |
| `-word`, `-tag:x` | exclude |

### 6.2 Ranking and results

- Title matches first (prefix beats substring), then FTS rank (`bm25` with the title column weighted higher), pinned notes before unpinned at equal rank, then `updated` descending.
- Each result shows the title, the space, the badges and one snippet with the match highlighted. Enter opens the note and places the cursor on the first match. Esc returns to the list.
- Results arrive within 50 ms for 10,000 notes (section 11). Typing never waits for the index; the title match shows at once and content matches merge in.

### 6.3 Index

SQLite with FTS5, outside the vault, rebuilt from the files at any time. Schema and rules in `STORAGE-FORMAT.md` section 9.

---

## 7. Sync, backup and safety

### 7.1 Why a local folder plus git

The owner chose a local folder (Q1). There is no Apple Developer account, so CloudKit is out in any case. Git gives both history and the remote backup: a repository stored outside the vault takes a snapshot every ten minutes when something changed and on quit, and pushes to a private remote when one is configured. A vault inside iCloud Drive or another synced folder keeps working, because git never writes into the vault; the sync-specific handling (placeholders, conflict versions) is F3, P2. ADR 0002 has the reasoning and the alternatives.

### 7.2 Rules

1. All reads and writes go through `NSFileCoordinator`. Writes are atomic (temp file in the same folder, then replace).
2. A watcher (FSEvents on the vault root) reports changed paths. Changed means a different modification date or size; the index then compares the content hash and skips files that only got touched.
3. An open note reloads from disk when the user has no unsaved edits. Otherwise the conflict banner appears (S11). Nothing is merged automatically.
4. (Synced folder, F3, P2) Conflict versions are listed in the Conflicts view until the user picks one. "Keep both" writes the other version as `<Title> (conflict YYYY-MM-DD HHmm).md`.
5. (Synced folder, F3, P2) A file that is not downloaded shows in the list with a cloud badge; opening it starts the download and shows progress.
6. The index is never a source of truth. "Rebuild index" in Settings deletes it and scans the vault; the scan of 10,000 notes finishes in under 20 s on Apple silicon.
7. History snapshots run through the shell runner off the main actor, never block typing and are logged in the activity log. A failed push is one activity line, not an alert.

---

## 8. Developer integrations and extension points

### 8.1 Link patterns (G1)

`.slate/links.json` holds an array of patterns. Each has `id`, `regex` (ICU), `url` with `$1`-style groups, `label`, `icon` (SF Symbol). The file is watched; a change applies at once. Defaults are generated on first launch from Settings H2. Schema in `STORAGE-FORMAT.md` section 7.

### 8.2 URL scheme (G2)

`slate://` is registered in `Info.plist` (`CFBundleURLTypes`). Handled in the Composition layer, parsed into a typed command, validated, then passed to a use case. No shell execution from a URL. Routes:

| URL | Effect |
|---|---|
| `slate://new?title=…&body=…&space=…&type=…&ticket=…` | Creates a note and opens it |
| `slate://open?ticket=ABC-2324` or `?title=…` or `?id=…` | Opens the matching note; creates a task note when `ticket` has no note |
| `slate://append?today=1&text=…` or `?ticket=…&section=…&text=…` | Appends text; creates the note when missing |
| `slate://capture` | Opens the capture field |
| `slate://search?q=…` | Opens the panel with the query |

### 8.3 CLI (G3)

`slate` is an executable target in the same package, installed to `~/.local/bin` by `Scripts/install.sh`. It writes vault files directly through the same Data layer as the app, so it works when the app is not running; the app's watcher picks the change up. For opening it calls the URL scheme.

```
slate new "ABC-2324 Profile screen leaks memory" --type task
slate open --ticket ABC-2324
slate append --today "Fixed the retain cycle in ProfileViewModel"
slate append --ticket ABC-2324 --section Findings "…"
slate today
slate search "retain cycle" --type task
slate list --space Tasks --status active --json
slate path --ticket ABC-2324
```

Reads of the index are read-only; when the index is missing the CLI falls back to a file scan. Output is plain text, `--json` for scripts.

### 8.4 Actions (G4)

`.slate/actions/<name>.json`: `title`, `icon`, `command` (an executable or script path), `when` (`always`, `task`, `hasBranch`), `output` (`activity`, `appendToNote`, `clipboard`). The script receives `SLATE_NOTE_PATH`, `SLATE_NOTE_TITLE`, `SLATE_TICKET`, `SLATE_BRANCH`, `SLATE_MR`, `SLATE_VAULT`. Actions show in the palette and in the note's menu. Every run goes through the shell runner and the activity log. Example actions shipped as files the user can edit: "Open worktree in Terminal" (finds the worktree by branch through `git worktree list`), "Copy standup" (prints Today's Log section in Slack format), "Open merge request".

### 8.5 Templates and types (C2, C11)

`_templates/<type>.md` is the body for a new note of that type; the header defaults per type live in `.slate/types/<type>.json` (built-in types ship inside the app and are written to the vault on first launch so the user can edit them). A new type is a new pair of files; the app picks it up on the next watcher event.

### 8.6 Other tools in the family

- DevHub: a "Notes" action on a worktree row can open `slate://open?ticket=<key from the branch>`. Slate's task header can offer "Open in DevHub" when DevHub registers a scheme. Both are one-line additions on each side; not part of v1.
- Claude Code: the CLI is the integration. A skill in the iOS repository can call `slate append --ticket … --section Findings` at the end of an investigation.

---

## 9. Settings

Listed in section 4.H. Settings live in `UserDefaults` through the `KeyValueStore` port, except the vault content configuration (`.slate/*.json`, `_templates/`) which lives in the vault so it syncs. Secrets (Jira token) live in the Keychain through the `SecretStore` port and never in `UserDefaults`, a plist or a log line.

---

## 10. Keyboard map (P0 unless marked)

| Keys | Where | Action |
|---|---|---|
| `⌥⌘N` | global | Toggle panel |
| `⌃⌥Space` | global | Capture field |
| `⌥⌘T` | global | Open Today (P1) |
| `⌘N` | app | New note in the current space |
| `⌘⇧T` | app | New task (ticket prompt) |
| `⌘K` | app | Palette (P1); in P0 focuses search |
| `⌘F` | app | Focus the header search; inside the editor a second `⌘F` opens find in note (P1) |
| `⌘⇧O` | app | Open as window |
| `⌘⇧N` | window | Open the note in a new window |
| `⌘0` | window | Toggle the sidebar |
| `⌘1` … `⌘9` | app | Space by position |
| `⌘⇧[` / `⌘⇧]` | app | Previous and next space |
| `⌘↑` / `⌘↓` in the list, `⌘⌥↑` / `⌘⌥↓` in the editor | app | Previous and next note |
| `⌘⇧M` | note | Move to space |
| `⌘⇧P` | note | Pin or unpin |
| `⌘⇧D` | task | Set done |
| `⌘⌫` | note | Move to Trash (inline confirm) |
| `⌘⇧S` / `⌘⇧W` | editor | Screenshot region / window |
| `⌘⇧V` | editor | Paste as code |
| `⌘⇧L` | editor | Toggle checkbox on the line |
| `⌘B`, `⌘I`, `` ⌘` `` | editor | Wrap with `**`, `*`, `` ` `` |
| `⌘⇧K` | editor | Insert link (`[text](url)` from the clipboard URL) |
| `⌘Enter` | editor | Open the link under the cursor |
| `⌥↑` / `⌥↓`, `⌘D` | editor | Move line, duplicate line (P1) |
| `⌘[` / `⌘]` | daily | Previous and next day (P1) |
| `Esc` | anywhere | Close popover, clear search, close panel |

All app shortcuts are listed in the menu bar menu of the window, so they are discoverable and changeable through System Settings → Keyboard.

---

## 11. Performance budgets and quality bar

Measured on an Apple silicon Mac with a 10,000-note vault (generated by a script in `Scripts/`), 1 GB of attachments.

| Measure | Budget |
|---|---|
| Panel open, warm | under 100 ms to the first frame with the list |
| Cold launch to a usable panel | under 1 s; the index loads lazily |
| Keystroke to glyph in a 5,000-line note | under 16 ms, no dropped frames while typing |
| Search results for a two-word query | under 50 ms |
| Full re-index of 10,000 notes | under 20 s, in the background, with progress |
| Incremental index of one changed file | under 20 ms |
| Memory with the panel open and one note | under 150 MB |
| Quick capture save | under 200 ms from Enter to the file on disk |

Quality bar for every milestone: `Scripts/build.sh` prints `layers: ok` and the app path, `Scripts/test.sh` prints one passing line, a manual run of the scenarios touched by the milestone, `CHANGELOG.md` and `docs/STATUS.md` updated.

---

## 12. Risks and how the design answers them

| Risk | Answer |
|---|---|
| The editor eats the whole budget | The editor is a separate module with a small contract; v1 shows marks and only styles; a time-boxed spike compares an own highlighter with the open-source `MarkdownEngine` before M2 starts (`ROADMAP.md`) |
| A vault inside a synced folder (optional) | File coordination and hash-based change detection from day one; placeholders and the Conflicts view come with F3 (P2); git history as the second line of defence |
| External edits race with in-app edits | Loaded hash per open note, journal for unsaved text, banner instead of a silent overwrite |
| Renaming a note breaks links | Links resolve by title through the index; a rename rewrites links in the linking notes in one coordinated pass; a failed rewrite is reported, not hidden |
| Scope creep | Priorities per feature, milestones with "done when", ideas go to Appendix B |
| The index and the files disagree | The index is derived; Rebuild is one button; every read of a note goes to the file, never to the index |
| `screencapture` or `git` missing or slow | Doctor in Settings; every external command goes through the shell runner, is logged and can be cancelled |

---

## 13. Decisions taken with the owner (2026-10-16)

The former open questions and their answers. `docs/STATUS.md` carries them as numbered decisions.

| # | Question | Decision |
|---|---|---|
| Q1 | Vault location | A **local folder**, default `~/Documents/Slate`, chosen on first launch. Backup and history through git with the repository outside the vault and an optional private remote (section 7). iCloud Drive is not the default; a vault inside a synced folder is supported later (F3, P2) |
| Q2 | iPhone app later | No. The format stays plain files, so the door stays open |
| Q3 | Obsidian compatibility | Kept. It means three invisible things: a link is written as `[[File name]]`, files live in `_attachments/`, the header is YAML. The cost is one rule (the file name follows the title). The gain is a second editor for the same files at any time |
| Q4 | Jira token in the Keychain for read-only details | Yes, P1, off until a token is set |
| Q5 | Merge request status | Through `glab api`, no token stored (P2) |
| Q6 | Separate app or a DevHub tab | Separate app; both link through URL schemes |
| Q7 | Name | Slate, until the owner renames |
| Q8 | Appearance | Follows the system |
| Q9 | Daily notes | On by default |

One more requirement from the owner: **the UI must be of high quality and simple to understand.** `UX.md` is the rule book for that; every screen is checked against it.

---

## Appendix A. Reference layouts

Panel:

```
┌─────────────────────────────────────────────────────────────────────┐
│ ▾ Tasks      [ Search …                         ]   + ⌘N  ⧉  ⚙     │
├──────────────────────┬──────────────────────────────────────────────┤
│ ACTIVE               │ ABC-2324 Profile screen leaks memory             │
│ ● ABC-2324 Profile s… │ [ABC-2324] [feature/ABC-2324-profi…] [!1234] │
│   fixes in ProfileVM… │ [active ▾]  #audio #memory      updated 10:01 │
│   10:01  📎2 ☐3      ├──────────────────────────────────────────────┤
│ ● ABC-2301 Onboard…  │ ## Context                                   │
│ TODO                 │ Leak after the second call. Instruments shows│
│ ○ ABC-2330 Pills …   │ `ProfileViewModel` retained by a delegate…  │
│ DONE (12)         ▸  │                                              │
│                      │ ## Plan                                      │
│                      │ - [x] Reproduce on iPhone 16 simulator       │
│                      │ - [ ] Break the delegate cycle               │
│                      │                                              │
│                      │ ```swift                                     │
│                      │ weak var delegate: EngineDelegate?   │
│                      │ ```                                          │
│                      │ ![](../_attachments/20261016-100142-sim.png) │
├──────────────────────┴──────────────────────────────────────────────┤
│ 23 notes   history 09:50 · pushed   Activity                        │
└─────────────────────────────────────────────────────────────────────┘
```

Capture field:

```
┌──────────────────────────────────────────────────────┐
│ Engine delegate must be weak, check the RTM one too  │
│                                                      │
│ [Inbox ▾] [note ▾]      ⏎ save  ⌘⏎ open  ⌥⏎ today   │
└──────────────────────────────────────────────────────┘
```

Window: the same as the panel with a sidebar on the left: Spaces (with counts), Tags, Smart views, Trash.

---

## Appendix B. Ideas backlog (not required)

- Note history diff view (git diff rendered side by side).
- "Standup from Today" through `claude -p`, posted to Slack through a DevHub Slack command.
- Clipboard history limited to the last 10 text items, for pasting into notes.
- A "Reading" space with a web clipper (Safari Services + readability conversion).
- Encrypted notes for secrets (age-encrypted blocks). Probably not: the Keychain exists.
- Sync of `.slate/` settings across Macs is free with iCloud; a `settings.json` export for `UserDefaults` values.
- Periodic "Inbox is growing" reminder as a notification.
- Linking a note to a Figma frame with a thumbnail through the Figma API.
