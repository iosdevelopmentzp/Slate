# Status

Last updated: 2026-10-16

## Stage

M0 to M7 built and merged into `main` (commit `aad80a0`). The owner tried the app and asked for a simpler, softer first version: **Phase 2, milestones S1 to S4 of `docs/ROADMAP.md`** (ADR 0007 scope, ADR 0008 rich text editor, `UX.md` revision 2). Next: S1.

The Screens table below describes the M7 state and is the inventory for S1: everything not in `SPEC.md` section 0.9 leaves the UI.

## Screens

| Screen | State | Notes |
|---|---|---|
| First launch | real | "Where should Slate keep your notes?", the default path, Choose…, Start. A folder that cannot be prepared shows the reason under the path |
| Panel | real | Header: folder menu (All notes, folders, Trash, Sort by), search (`⌘F`), New (`⌘N`; the menu offers Note, Task, Snippet, Meeting, Today and Insert Template), Open as window (`⌘⇧O`), Settings (`⌘,`). Footer: note count and "saved just now". The status item: left click toggles the panel, right click shows New Note, New Task, Quick Note, Today, Open Window, Settings, Quit |
| Window | real | The panel plus a sidebar: Folders with counts, New folder (+), Tags with counts (click searches `tag:`), Trash. Right click on a folder: Rename, Icon, Move up, Move down. `⌘0` hides the sidebar. No Saved searches yet (C9, M6) |
| Capture field | real | `⌃⌥Space` from any app: a 520 pt field 20 % down the screen, folder and kind menus, hints. Enter saves, `⌘Enter` saves and opens the note in the panel, `⌥Enter` adds a line to Today's Log, `⇧Enter` is a new line, Esc closes and keeps the draft, a click outside closes. The panel is non-activating (`PLAYBOOK.md` section 2). A text starting with a ticket key becomes a task. No pasted images in the field yet |
| Tasks | real | A folder whose default kind is Task groups its list into Active, To do and Done (Done is folded). The editor chips: the ticket opens the tracker (or copies when no tracker is set), the branch copies, the merge request opens, the status is a menu. `⌘⇧D` marks the task done. A new task takes the ticket from its title and gets the branch `feature/<ticket>-<slug>` |
| Daily | real | `⌥⌘T` from any app, Today in the New menu and in the status menu: `Daily/YYYY-MM-DD.md` from the daily template, with the open checkboxes of the latest earlier daily note under "Carried over". `⌘[` and `⌘]` go to the day before and after |
| Note list | real | Rows: status dot, kind icon for non-plain notes, title, relative date, pin, preview, badges (ticket, subfolder, images and files, open checkboxes). Hover and right click: Pin, Move to, Duplicate, Archive, Move to Trash (inline confirmation, toast with Undo). Badges come from the in-memory index |
| Trash | real | Lists trashed notes with their folder and age; Restore and Delete now on hover and right click (Delete now asks inline and moves the file to the macOS Trash). "Notes are removed from the Trash after 30 days." The purge runs at launch and once a day with the days from Settings |
| Editor | real | Title field, chips, autosave, the "Changed on disk" banner (M1). Markdown styling with visible marks, code blocks with highlighting and a Copy button, checkboxes, list editing, images under their line, paste rules with the "Paste as code" bar, screenshots, `⌘`-click links (M2). `[[` completes note names, `#` completes tags; a link to a missing note makes that note; tag chips under the title search the tag (M3). Outline popover (headings, click jumps), find and replace in the note (`⌘F` with the text focused, `⌥⌘F`), move line (`⌥↑`/`⌥↓`), duplicate line (`⌘D`), comment in code (`⌘/`), backtick pairs and closing fences on Enter, the ticket's title, status and person under the chips when a token is set (M7). "Changed on disk" offers Keep mine, Take theirs and Open both; unsaved text is kept in a journal every second and offered with Restore and Discard when the note opens again (M5). No link titles (P1), no hover preview of a link target |
| History | real | A clock button next to the title lists the versions of the note (git snapshots outside the notes folder) with Restore. The footer says "history 09:50", "pushed" or "push failed" (opens Activity) |
| Activity | real | The footer button opens a list of what went wrong (and a few successes) with Clear and Copy |
| Note windows | real | "Float on Top" (note menu, File menu) opens the note in a small panel that stays above other apps; "Open in New Window" (`⌘⇧N` in the window) opens it in a normal window. Each has its own editor; `⌘W` closes; checkbox clicks work. Editors on the same note reload after the other one saves |
| Main menu | real | While the window is open Slate shows a menu bar (and a Dock icon) with every shortcut of `SPEC.md` section 10: Slate, File, Edit, Format, Note, Go, View, Window. Editor items reach the text through the responder chain and are off when the text has no focus |
| Palette | real | `⌘K`: one field over the panel or the window. Empty: recent and often opened notes and the main commands. Typing: notes (titles at once, text from the index, filters work) and commands (new notes, Today, Open TODOs, folders, saved searches, templates, actions, export, versions, Rebuild search, Settings). Arrows, Enter, `⌘Enter` opens in the window, `⌘C` copies the note path, Esc closes |
| Open TODOs | real | A list of every open checkbox, grouped by note or by ticket. A click on the box checks it in its file and the open editor reloads. Double click opens the note. In the folder menu, the sidebar and the palette |
| Saved searches | real | From `.slate/views.json` (written on first launch with the five defaults of `STORAGE-FORMAT.md` 7.3): in the sidebar, the folder menu and the palette; a click runs the search over all notes |
| Extension points | real | `slate://new`, `open`, `append`, `capture`, `search` (cold start too). The `slate` CLI: `new`, `open`, `append`, `today`, `search`, `list`, `path`, `version`, with `--vault` and `--json`. Services → Add to Slate makes a note from the selected text. Actions from `.slate/actions/*.json` (three examples written on first launch) in the note menu and the palette, with the output in Activity, the clipboard or the note. The note menu (`…`): Copy as Markdown, Copy for Slack, Save as HTML, Save as PDF (both into Downloads, then shown in Finder) |
| Search | real | The header field searches titles, text, tags and tickets in the current folder ("Search all notes" widens it) with the filters of `SPEC.md` 6.1. Title matches show at once; the index answers within 80 ms plus the query. Rows show the snippet with the words in bold; Enter or a click opens the note with the caret on the first match. Esc clears. No palette yet (A7, M6) |
| Settings | real | One window with General (Open at login, the quick note folder, text size, appearance, Trash days, daily notes on or off, carry-over, daily template, Doctor with the notes count, the last version, the remote, the three shortcuts and Rebuild search), Notes folder (Choose another folder…), Shortcuts (three recorders), Links (tracker and git host addresses, ticket pattern, labels, email and API token for ticket details with Test; Save writes `.slate/links.json`; the token goes to the Keychain), History (versions on or off, interval, remote, push on quit, Save a version now) |

States: planned, placeholder, mock, real, partial (say what is missing).

## Decisions

Numbered. What, then why. A later session must not undo these without a new numbered entry that explains the change.

1. Files are the source of truth; the index is derived. ADR 0001.
2. The vault is a **local folder** by default (`~/Documents/Slate`). History through git with the repository outside the vault, optional remote. iCloud Drive is not the default; a vault inside a synced folder is supported later (F3, P2). ADR 0002. Owner's answer to Q1.
3. No iPhone app planned. Owner's answer to Q2.
4. Obsidian compatibility stays: wikilinks by file name, `_attachments/`, YAML header. It costs nothing visible and gives a second editor for the same files. Q3.
5. No sandbox, ad-hoc signing, no developer account, `LSUIElement`. ADR 0003.
6. Layered local package, the DevHub contract, plus `SlateEditor` and `SlateCLI`. ADR 0004.
7. Thin Markdown editor on TextKit 2, marks visible; M1.5 spike decides own core vs `MarkdownEngine`. ADR 0005.
8. The app knows no project: tracker, hosts, patterns come from Settings and `.slate/`. No build-time word list; the rule is reviewed by reading. ADR 0006.
9. UI and UX follow `docs/UX.md`: native macOS look, three visible concepts (Folders, Notes, Tags), everything else behind a command or a setting.
10. Open questions Q4 to Q9 of the spec take their defaults: Jira token in the Keychain is acceptable (P1, off until set), merge request status through `glab api` (P2), a separate app from DevHub, the name stays Slate, appearance follows the system, daily notes on.
11. Dependency versions at bootstrap: GRDB.swift 7.11.1, swift-markdown 0.9.0, KeyboardShortcuts 1.10.0, swift-argument-parser 1.8.2.
12. What M0 left out of the DevHub copy, and why:
    - `WindowAppearance` and the forced light scheme: Slate follows the system appearance (`PLAYBOOK.md` section 1, `UX.md` section 1). `Theme` maps to system colours.
    - `PlainTextEditor`: `SlateEditor` is the one text view. `SyncText`, `Countdown`, `StatusItemTitle`, the tab bar and the feature registry: they serve DevHub features only.
    - `CommandLog`, `CommandEvent`, `CommandKind` and `LineBatcher`: `ShellRunner` records one `CommandRecord` per finished command, as `ARCHITECTURE.md` section 4.3 says. `ActivityLog` keeps the failed ones; `ActivityRecorder` hops to the main actor with a `Task`.
    - `MainActor.assumeIsolated` and `DispatchQueue.main` in `AppWindows`, `HostWindowReader` and the recorder: replaced with `Task { @MainActor … }` (`ARCHITECTURE.md` sections 3 and 11).
    - The pinned floating window became a normal window (`UX.md` section 2.2). `isPinnedWindow` became the `Surface` environment value.
    - Verba rows of `BOOTSTRAP.md` section 3 are not copied yet; each one comes with the milestone that needs it.
13. Until a port has a live implementation, `Ports.live(pending:)` takes it from `Ports.mock()` (`ARCHITECTURE.md` section 4.3). M1 replaces the mock index and config with live ones and removes the parameter.
14. M1 removed `Ports.live(pending:)`; every port has a live implementation (`Ports.live(root:keyValues:)`). This closes decision 13.
15. Until M3 the live index was `MemorySearchIndex`. M3 replaced it with `GRDBSearchIndex` behind the same port and removed it (decision 31).
16. The panel and the window share one `EditorStore` until a second editor surface exists (more windows and floating notes, M7). Only one of the two is open at a time, because opening the window closes the panel.
17. A small conflict banner (Keep mine, Take theirs) came forward from M5, so a conflict never leaves typed text without a way to save it. M5 adds Open both, the journal and the S11 check.
18. `VaultChange` is `.paths(Set<VaultPath>)` or `.rescan`, without a kind: the reindex reads the disk for each path. `ARCHITECTURE.md` section 4.1 says so.
19. Stem rule, `STORAGE-FORMAT.md` 3.1 steps 3 and 4: tabs and line breaks count as whitespace (step 4 collapses them); step 3 removes the other control characters. No format change.
20. The New menu offers Note, Task, Snippet and Meeting. Daily comes with C10 (M4), because a daily note is named by its date and opened, not created twice.
21. M1 is one commit, not one per feature ID: C1, C2, C5, C7, C8, D6, D7, F1, F2 and B2 share the new ports, use cases and stores, and the steps between them would not build.
22. `STORAGE-FORMAT.md` section 1 said "default in iCloud Drive"; it now says `~/Documents/Slate` as ADR 0002 decided. This fixes the text, not the format.
23. Quit saves through `AppContainer`: a selector observer for `willTerminate` (main actor, no `assumeIsolated`) runs `EditorStore.pendingSave()` off the main actor and waits up to 3 s.

24. M1.5 editor spike: the own TextKit 2 core wins (open 71 ms, keystroke 2.2 ms on the 5,000-line fixture) over `MarkdownEngine` 0.9.0 (975 ms, 79 ms). No new dependency. ADR 0005 amendment has the numbers. The two spike branches `spike/own-core` and `spike/markdown-engine` stay local and are not merged; M2 takes the own-core files from `spike/own-core` as its start.
31. M3 index: `GRDBSearchIndex` in `~/Library/Application Support/Slate/<vault-id>/index.sqlite` with the schema of `STORAGE-FORMAT.md` section 9. A file made for another vault path or schema version is deleted and rebuilt. Two files with the same header `id` cannot share a row: the second one is indexed under its path id (`path:…`). Note aliases are not indexed yet (C12, P2): `[[Name]]` resolves by file name only.
32. Search runs in the current folder; a line above the results says "In Tasks" with "Search all notes". The header field keeps filtering the Trash by name when the Trash is shown. `is:trashed` matches nothing in search, because the Trash is its own list.
33. A rename rewrites `[[Old]]` links only in notes where the link resolves to the renamed note, so a link to another note with the same name in another folder stays. The toast says how many notes were updated; failures go to Activity.
34. `IndexFactsPolicy` (Domain) builds the index facts from the line-based policies; `IndexedNoteBuilder` adds what swift-markdown sees (code blocks, images, URLs, attachments). The spy and mock builders use the policy, so tests over spies index tags, links and checkboxes like the app.
35. M3 is one commit: the search port grew by eight methods, and the spies, the mock, the GRDB index, the rename use case and the stores change together.
36. M4 global hotkeys: the `KeyboardShortcuts.Name` values live in `SlatePresentation` (`Shared/KeyboardShortcuts+Slate.swift`) and `AppWindows` registers them, because the Settings recorder (Presentation) and the handlers need the same names and Presentation cannot import Composition. `PLAYBOOK.md` section 3 named `SlateComposition/Hotkeys.swift`; the playbook now says so.
37. M4 quick note: the first line becomes the title and the other lines the body. A text that starts with a ticket key is a task (in Tasks, from the task template unless more lines follow). `⌥Enter` writes `- HH:mm text` under Today's "Log".
38. M4 links: `.slate/links.json` is written when the owner saves Settings → Links, not on first launch, because the app has no tracker address before that (ADR 0006). Saving keeps every pattern whose id is not one of the three defaults. Until then a ticket chip copies the key. A pasted URL that matches a pattern becomes its short form at once, and `⌘Z` brings the full URL back; the toast says so.
39. M4 tasks: a new task writes `ticket`, `branch` (from the type's `branchPattern`) and `status: todo` into the header. The title keeps the ticket (`titlePattern` `{{ticket}} {{title}}`).
40. M4 settings: text size is the only editor font setting (the font itself stays the system font, `UX.md` section 1). Appearance sets the appearance of Slate's own windows, never `NSApp.appearance` (`PLAYBOOK.md` section 1). The Trash days setting is stored now and used by the auto-empty in M5. Changing the notes folder stops the windows and the change feed and opens the new folder; the old folder and its index stay.
41. Section append (`STORAGE-FORMAT.md` section 4): an empty section gets one blank line after its heading before the first entry, and an append without a section is added as its own paragraph. No format change.
42. M4 is one commit: the capture, daily and task features share the new use cases, the settings and the windows.
43. M5 history: versions are snapshots of the whole notes folder in `~/Library/Application Support/Slate/<vault-id>/history.git`, every 10 minutes (Settings) when something changed, at launch and on quit. A push follows each snapshot when a remote is set; "Push when Slate quits" decides the push on quit. Restore takes a snapshot first, then writes the old body and details through the normal save; it keeps the current title and id, so no rename happens.
44. M5 journal: one JSON file per note in `<support>/journal/`, written at most once a second while the text differs from the file, removed after a save. A journal that is newer than the file and differs from it shows "Unsaved text from … was found." with Restore and Discard. Nothing restores without the click.
45. "Open both" (S11) writes my text as a new note `<Title> (conflict YYYY-MM-DD HHmm)` in the same folder and shows the version on disk. This is the naming of `SPEC.md` 7.2 for "Keep both".
46. Delete now and the purge move files to the macOS Trash with `FileManager.trashItem` (Foundation), not `NSWorkspace.recycle`, so `FileTrashRepository` stays without AppKit. Tests pass their own `recycle` closure so nothing reaches the real Trash.
47. `CommandRecord` has `toleratedExitCodes`, so an expected exit code (git's 1 and 128) is not a failure in Activity.
48. M5 is one commit: the journal, the conflict copy, history, purge and Activity share the editor, the footer and the assembly.
49. M6 URL scheme: `AppContainer` is the app delegate (`@NSApplicationDelegateAdaptor`) and gets URLs through `application(_:open:)`; `AppContainer.live()` is gone and `AppContainer` has a public `init()`. `URLCommandParser` is a Domain policy (shared with the CLI), not a Composition type as `ARCHITECTURE.md` section 8 had it.
50. M6 Info.plist: `Config/Slate-Info.plist` with the URL type and the service, merged with the generated keys. It is outside `Slate/` so the synchronized folder does not copy it as a resource.
51. M6 actions: `command` runs as `/bin/zsh -c "<command>"` with the note environment and the notes folder as the working folder, so an action can be a one-line shell command or a script path. Three example actions are written once when `.slate/actions/` is missing; they use only `SLATE_*` values (ADR 0006). A 60 s limit stops the action.
52. M6 export: Save as HTML and Save as PDF write into Downloads and show the file in Finder instead of a save panel (`UX.md` principle 5). The PDF is the HTML page drawn by an `NSTextView`.
53. M6 CLI: the notes folder comes from `--vault`, then `SLATE_VAULT`, then the app's `vault.path`. Commands that read the index (`append --ticket`, `search`, `list`, `path`) first run the scan for changed files, so they see edits made while the app was closed. The CLI writes the index too (WAL lets the app read at the same time).
54. M6 palette: an overlay inside the panel or the window, not its own window. Recent notes are the last 20 opened (`navigator.recent`); "often" means opened more than twice.
55. M6 is one commit: the URL scheme, the CLI, Services, actions, saved searches, Open TODOs, the palette and export share the Info.plist, the config port and the stores.
56. M7 note windows: each note window and floating note has its own `EditorStore` (`PresentationAssembly.makeNoteEditor()`, `followsNavigator = false`); the panel and the main window still share one. A store reloads its note after `noteSaved` from another store (the hash check makes it a no-op for its own saves).
57. M7 main menu: an `LSUIElement` app has no menu bar, so Slate switches to the regular activation policy while the main window is open and installs its own `NSApp.mainMenu` (`MainMenuBuilder`); closing the window goes back to the accessory policy. The panel keeps working without a menu bar through the SwiftUI shortcuts.
58. M7 keys that the text also uses (`⌘↑`, `⌘↓`, `⌘⌫`): when a text view has the focus the shortcut sends the normal text action (to the start or end of the text, delete to the start of the line); otherwise it moves in the list or asks to move the note to the Trash. `⌘⇧M` opens the palette with "move to ". Esc in the panel closes the palette, then clears the search, then closes the panel; Esc in the editor goes up to the panel (completion stays on F5 and `⌥Esc`).
59. M7 ticket details: Jira Cloud's REST API v3 with basic auth (email from Settings, token from the Keychain, service `local.slate.app`); a 5 s timeout; a failed key is not asked again until the token changes. Offline the task shows the key only.
60. M7 daily settings (H3) live in `UserDefaults` as `DailySettings`. With daily notes off, Today shows a toast instead of making a note.
61. The CLI has a hidden `--support-folder` option so tests never write into `~/Library/Application Support/Slate`.
62. M7 is one commit: the editor commands, note windows, the keyboard map, ticket details and the settings share `AppWindows`, `EditorStore` and the editor module.
25. Branches during the long build: one branch per milestone, each made from the one before (`m1.5-editor-spike`, `m2-editor`, `m3-index-and-search`, …). Merging the last one brings all of them.
26. M2 editor details: a tag needs at least one letter (`#123` stays text, it is the issue pattern of `links.json`). Tab indents a list item by the width of its own marker plus one space (`- ` two spaces, `1. ` three). Remove Image deletes the line (Undo brings it back); the file stays in `_attachments/` until "Clean attachments" (M5). The "Paste as code" bar lives inside `SlateEditor`, so Enter and Esc reach it while the text has focus.
27. The host gives text to the editor with `EditorInsertion(token:markdown:)`, like `EditorFocusRequest`; the editor inserts it on its own line once per token. `ARCHITECTURE.md` section 6.1 had an `EditorCommands` object; the token value replaced it, so no store holds an AppKit object.
28. `PasteKindPolicy` of `ARCHITECTURE.md` section 4.4 is `PasteClassifier` inside `SlateEditor`; the CLI and the use cases do not need it. `ARCHITECTURE.md` now says so.
29. The panel hides for a screenshot through `PanelVisibility` (two closures that `AppWindows` sets); the window stays. Quick Look runs through the `WorkspaceOpening` port with a `QLPreviewPanel` data source in `SlateData/System`.
30. M2 is two commits: the editor module (D1, D2, D3, D5 styling), then attachments, paste and screenshots (D4, B4, B5), because the handlers for D4, B4 and B5 share one change to `EditorStore`.

14. Phase 2 scope (owner, 2026-10-16): v1 shows Folders and Notes only. Parked features keep their Domain and Data code and tests; their Presentation code is removed. ADR 0007.
15. The editor is rich text on TextKit 2; Markdown stays the file format through `MarkdownRichText.read` and `write` with raw blocks for anything outside the subset of `STORAGE-FORMAT.md` section 11. ADR 0008 replaces ADR 0005.
16. The look follows `UX.md` revision 2: rounded cards and pills, no divider lines, tinted folder icons, a format bar, friendly empty states.
17. First launch creates one folder, `Notes`, and no templates, types, views, links or actions. Existing vaults keep working.

## Next steps

1. S1 Simplify (`docs/ROADMAP.md`, Phase 2).
2. S2 Folders and the soft look.
3. S3 Rich text editor.
4. S4 Polish and the owner's pass.

## Known gaps

- The agent did not run the manual checks. A scripted click opens the panel but does not make Slate the active app, so scripted keystrokes go to the frontmost app (a few of them went to the Terminal during this session). The borderless panel also hides its content from the Accessibility API.
- No shortcut for Move to Trash: `⌘⌫` would take the key from the editor text. No `⌘⇧M` move picker. Both are in the row menu.
- No drag of a row onto a folder (C8 part). Moving works from the row menu.
- No way to delete a folder.
- Esc does not close the panel yet (`UX.md` section 6). The search field clears on Esc.
- Capture (M4): the field does not take pasted images or files yet (`SPEC.md` 3.4). The agent did not test that the source app keeps the focus; scripted key presses do not reach the panel (first gap above).
- Link chips (M4) are coloured text on a tinted background, without the SF Symbol from `links.json`.
- The status chip and the other header chips are not reachable with Tab yet (keyboard pass, M7).
- Search (M3): no progress bar or "Indexing 3,120 of 10,000" line during the first full scan (`UX.md` section 5). The list fills as the scan runs.
- Search (M3): typing `#` offers tags only after one letter, so `#` alone at the start of a line stays a heading.
- The list column uses `HSplitView` (240 to 400 pt); its width is not saved.
- History (M5): no diff view and no preview of a version before Restore (Appendix B). The first snapshot of a large folder runs at launch in the background and can take seconds.
- Quit waits up to 3 s for the save and the last snapshot; a slow push is cut off and runs at the next snapshot.
- `.claude/skills/add-feature`, `add-use-case`, `build-and-run` and `update-docs` and the example in `.claude/rules/presentation.md` still show DevHub features.
- Editor (M7): no heading fold (D8). TextKit 2 has no simple way to hide paragraphs; the outline popover covers moving through a long note.
- Dark mode pass (M7) was done by reading the code: every colour is a `Theme` token, a `Tint` or a system colour, and the editor uses dynamic `NSColor`s. Nothing was looked at on screen.
- The main menu (M7) appears only while the main window is open, because Slate has no Dock icon otherwise.
- Editor (M2): no title fetch for a pasted URL (P1); no hover preview of a link target; file links show as coloured links, without an icon, and cannot be dragged out to Finder; the language of a code block shows on its fence line, not as a separate label; Remove Image does not ask first (Undo works).
- Editor (M2): typing latency was measured by a test on the 5,000-line fixture (2.2 ms median), not with Instruments. The Screen Recording prompt of `PLAYBOOK.md` section 11 was not checked by the agent.
- Previews in package files were not opened in Xcode yet.
