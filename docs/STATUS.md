# Status

Last updated: 2026-10-18

## Stage

Phase 2 is built and merged into `main` (S1 Simplify, S2 Folders and the soft look, S3 the rich text editor, S4 Polish, then sub-folders, ADR 0011). **Phase 3 is built: S5 Agents and the notes folder (ADR 0010), S6 Tables level 1 and S7 images in table cells (ADR 0009). Phase 4 is built: S8 Projects and files, S9 Agents and projects (ADR 0014), S10 Versions (ADR 0015).** Next: the owner's manual checks 40 to 68. The owner runs the manual checks below; every item passes or becomes a numbered gap. M0 to M7 stay in `main` (commit `545e0d6` is the last commit before S1 and holds every removed view).

Phase 3 run (2026-10-17), what is done and what is left:

1. Done: S5 (`1f625d3`), S6 (`92d6c4e`), S7 (`7e4b5c7`). Every item of the three scopes is built; `Scripts/build.sh` prints `layers: ok` and `Scripts/test.sh` passes 604 tests.
2. Left for the owner: manual checks 40 to 48 below, among them a real run of Claude Code against `slate mcp`, typing in tables in the running app, and a real drop of an image on a cell.
3. Left in code: the gaps marked S5, S6 and S7 under Known gaps (for example a card dropped into the note text, keyboard entry into a table, accessibility of table cells, manual column widths).

## Removed in S1 (ADR 0007)

The Presentation code below was deleted. Domain and Data code and tests stay. To bring a feature back, start from commit `545e0d6`.

| Feature | Removed from Presentation |
|---|---|
| Note kinds, New menu, Insert Template | `Shell/NewNoteMenu.swift`, kind menu of the quick note field, kind icons on rows and results |
| Tasks, tickets, branches, status, `⌘⇧T`, `⌘⇧D` | `EditorStore+Tasks.swift`, `NoteChip`, `NoteChipsMapper`, `NoteStatusText`, `TaskGroupText`, task groups in the list, status dots and badges |
| Ticket details | `Features/Issues/IssueStore.swift` |
| Today, daily notes, `⌥⌘T`, `⌘[`, `⌘]`, `⌥Enter` | `Features/Daily/DailyStore.swift`, the Today hotkey, the daily section of Settings |
| Tags and `#` completion | tag rows in the sidebar, tag chips, `SearchStore.tags`, `showTag` |
| Saved searches and Open TODOs | `Features/Todos/`, saved rows in the sidebar and the folder menu, `ListSource.todos`, `showSaved` |
| Palette `⌘K`, `⌘⇧M` move picker | `Features/Palette/`, the recent and often lists of `Navigator` |
| Actions, export, Copy for Slack, Copy as Markdown | `EditorStore+Export.swift`, `Views/NoteMenu.swift`, `Shared/ActionRunner.swift` |
| Float on Top, note windows, `⌘⇧N` note window | `Features/Floating/`, `Shell/NoteWindowController.swift`, `EnvironmentValues+OpenNoteWindow.swift` |
| Outline | `Views/OutlineView.swift` |
| Links and History pages of Settings | `LinkSettingsView.swift`, `HistorySettingsView.swift`, `SettingsStore.saveTracker` |
| Footer history, push state, Activity button | parts of `FooterView.swift`; Activity is in Settings → General → Check-up |
| Archive in the row menu | `NoteListStore.archiveNote` |
| Link patterns in the editor | `EditorConfiguration.linkPatterns` is empty; pasted URLs stay as they are |
| First-launch files | `_templates/`, `.slate/types/`, `views.json`, `actions/` and the five extra folders are no longer written |

## Screens

| Screen | State | Notes |
|---|---|---|
| First launch | real | "Where should Slate keep your notes?", the default path, Choose…, Start. A new folder gets `Notes/` with the welcome note, `_attachments/` and `.slate/spaces.json` only |
| Panel | real (S2) | Three columns like the window: sidebar (`⌘0` hides it, remembered), the list, the note. The status item: left click toggles the panel, right click shows New Note, Quick Note, Open Window, Settings, Appearance, Quit. The resize grip sits in the bottom-right corner |
| Window | real (S2) | The same three columns under a transparent title bar; the sidebar title sits next to the window buttons |
| Sidebar | real (S2) | "Folders" with Open as window (panel) and Settings at the top. All notes, the folders (tinted icon, name, count, soft pill when selected), Trash, and "+ New folder" at the bottom (`⇧⌘N`). Double click renames inline. Right click: Rename, Colour (eight colours with dots), Icon (16 named icons), Move up, Move down, Delete folder. Delete asks in place ("Delete "Ideas"? Its 4 notes move to Notes. Yes · No", 5 s, Esc cancels) and shows a toast with Undo. A note card dropped on a folder moves there. Sub-folders (ADR 0011): a tree with arrows (open state remembered), indented rows with an outline folder icon, New folder inside in every folder menu, Rename and Delete folder for sub-folders, drop a card on a sub-folder |
| Quick note field | real (S4) | `⌃⌥Space` from any app: a 520 pt rounded card (radius 14, surface colour, the system shadow), "Type a note…", the folder as a tinted chip on the left, "⏎ Save" on the right. Enter saves, `⌘Enter` saves and opens, `⇧Enter` new line, Esc closes and keeps the draft |
| Note list | real (S2) | The folder name (`.title2`), a round + button, a rounded search field and a thin progress line. Cards: title, date, pin, two-line preview; 12 pt padding, 10 pt radius, 6 pt gap; soft tint when selected or hovered. A "…" button on hover and the right-click menu: Pin, Move to, Duplicate, Move to Trash ("Move to the Trash? Yes · No" in the card). Cards can be dragged onto a folder. Empty folder: "Nothing here yet." with New note and `⌘N`. In a folder with sub-folders: sub-folder rows first (icon, name, count, chevron), then the folder's own notes; inside a sub-folder a back chevron before the title |
| Trash | real (S2) | Cards with the folder and the age; Restore and Delete now on hover ("Delete now? Yes · No"); "Notes are removed from the Trash after 30 days." under the list; "The Trash is empty." |
| Editor | real (S3) | Title field (24 pt bold, up to two lines, placeholder "Title") and the versions button (clock); the format bar (36 pt, radius 10): style menu, Bold, Italic, Strikethrough, Checklist, Bulleted, Numbered, Quote, Link, Image, "…" with Divider and Screenshot. Rich text without marks: title 24, heading 18, subheading 15 semibold, body 15, monospaced 13; round checkboxes, bullets, numbers, quote bar, code and raw blocks on a tint, images as rounded blocks (max 360 pt high), dividers. List keys, typing shortcuts ("- ", "1. ", "[] ", "# ", "> "), `⌘K` link popover, `⌘`-click opens links, double-click on an image opens Quick Look. The text column is at most 720 pt wide; "Saved" fades in for a second after a save. Empty: "Pick a note or press ⌘N." Autosave, journal with Restore and Discard, the "Changed on disk" banner |
| Versions | real | The clock button lists the versions of the note with Restore. Snapshots run quietly with the stored settings |
| Search | real (S2) | Titles and text in the current folder, "Search all notes" widens it. Cards show the matched text with the words in bold and the folder name. "No notes match." with Clear search. No filters are offered |
| Settings | real (S4) | Two pages. General: notes folder with Choose another folder…, Open at login, quick note folder, appearance, text size, "Back up to" (a git address) with "Back up now", Trash days, Check-up (checks, Check again, Activity, Rebuild search). Shortcuts: Open Slate, Quick note, New note |
| Main menu | real (S3) | While the window is open: Slate, File (New Note, New Folder, Quick Note), Edit (with Find in Note `⌥⌘F`), Format (the five styles, the three lists, Quote, Indent, Outdent, Bold, Italic, Strikethrough, Link, Image, Divider, Screenshot), Note (Pin, Move to Trash), Go (previous and next note and folder, All Notes, folders `⌘1`…`⌘9`), View (sidebar, Appearance), Window |
| Extension points | real, no UI | `slate://` and the `slate` CLI (`new`, `open`, `append`, `search`, and the parked `today`), Services → Add to Slate (a plain note in the quick note folder) |

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

63. S1 parked-word check: `git grep -n -i -E` for the ten words over `Sources/SlatePresentation`, word-like. The hits that stay are Swift and AppKit names, not features: `Task {…}`, `.task(id:)`, `refreshTask` and the other `*Task` properties, and `NSImage.isTemplate`.
64. `SpacesConfig.defaults` is one folder, `Notes` (`folder.fill`); the capture and archive fallback is `Notes`. The six folders of M1 are `SpacesConfig.sixFolders`, used by the test spies so the parked use cases keep their tests.
65. `slate://open` goes through `OpenTargetUseCase` (Domain): id, title, and ticket. A ticket without a note still makes a task note, because the CLI contract (`slate open --ticket`) stays (ADR 0007, kept but quiet). Presentation only shows the outcome.
66. The quick note field and Services always save a plain note (`type: note`); a leading ticket key no longer makes a task.
67. The New note global shortcut has no default keys: `UX.md` section 8 lists only two global keys, and a third default could take a key from another app.
68. Activity lives in Settings → General → Check-up as a button with a popover. Toasts that point to it say "See Activity in Settings". S4 adds "Details" on error toasts.
69. Search offers no filters. The parser still reads `tag:` and the others when typed by hand; nothing on screen mentions them.
70. The search hit field `snippet` is now `excerpt` in Domain, Data and Presentation, so "snippet" only means the parked note kind.
71. The footer stays until S2 (note count, save state, Quit, resize grip). The Format menu keeps the M2 editor commands without Code, Paste as Code and Toggle Comment until S3 replaces the editor.
72. `VaultConfigRepository.ensureDefaults` writes only `spaces.json`. The writers for the example actions and the type files were removed from Data; they are in commit `545e0d6`.

73. S2 sidebar keeps an "All notes" row above the folders. `UX.md` section 2 draws only folders, but "Search all notes" and old navigator state need a place to land, and Apple Notes has the same row.
74. Deleting a folder: the quick note folder (`captureSpace`) cannot be deleted (menu item off, `VaultError.defaultFolder`). Notes at any depth move to depth 1 of the quick note folder with unique names. The folder is then removed when it holds no visible files, otherwise it goes to the macOS Trash with the other files in it (`FileVaultStore.removeFolder`, Foundation `trashItem`, tests pass their own closure). An archive pointer to the deleted folder moves to the quick note folder.
75. Undo of a folder delete (`RestoreSpaceUseCase`) makes the folder again at its old place with its icon and colour and moves back every note that is still where the delete put it, to its exact old path (sub-folders too).
76. `Space.color` is a `SpaceColor` (the eight names of `STORAGE-FORMAT.md` 7.1, unknown or missing means blue). New folders and folders found on disk get `folder.fill`; an old `folder` icon shows as `folder.fill`.
77. A new folder starts as "New folder" (then "New folder 2", …) in an inline field with the name selected. Enter or leaving the field makes it; Esc cancels. A name that cannot be used keeps the field open and the toast says why.
78. `Theme.base` and `Theme.surface` are own dynamic colours (light 0.955 / 1.0 white, dark 0.135 / 0.19 white). The system window and control background colours are too close on macOS 26 for cards to show. Every other colour stays a system colour.
79. Accent buttons use `AccentButtonStyle` (own capsule in the accent colour), because `.borderedProminent` looks grey in a panel that is not the key window.

80. The sort order is fixed to "date changed" with pinned notes first; the stored `list.sort` is no longer read. `UX.md` has no sort control.
81. The window uses `.fullSizeContentView` with a transparent title bar; the sidebar title and, with the sidebar hidden, the list title leave 80 pt for the window buttons.
82. The agent checks the look by rendering views offscreen with `NSHostingView.cacheDisplay` from a throwaway test (not committed). This found the colour problem of decision 78.

83. S3 editor model: one paragraph per block; a line break inside a block is U+2028; images and dividers are U+FFFC with an attachment. The storage holds the real fonts and `RichTextStyler` restyles from the `slate.*` attributes after each edit. The content storage delegate of the M2 editor is not used, because the text has no marks to hide.
84. Links use an own `slate.href` attribute instead of `.link`, so `NSTextView` does not open them on a plain click and does not change their look. A wikilink has the `wiki:` prefix. `⌘`-click opens both.
85. On save, empty paragraphs and empty list items are dropped, and a blank line separates blocks. A nested list item is indented by the content offset of its parent item (CommonMark), so `1. ` children get three spaces.
86. Two lists of the same kind next to each other keep apart with the other marker (`*` after `-`, `)` after `.`), as CommonMark needs. This is in the subset of `STORAGE-FORMAT.md` section 11.
87. The `[[` completion of the M2 editor is gone: `UX.md` revision 2 has no completion popup. A typed `[[Name]]` is still read as a note link the next time the note opens.
88. Long notes: above 12,000 characters the editor writes Markdown 250 ms after the last key and flushes before every save, when editing ends and before another note opens. Below that it writes at once.
89. `⌘F` stays Search (`UX.md` section 8). Find in Note moved to `⌥⌘F`. Indent and outdent of list items are `⌘]` and `⌘[`, which are free since Today left.
90. Inline code has no button and no shortcut (`UX.md` section 4 has none); code from a file is shown and kept, and paste from Slate keeps it.
91. The default text size is 15 (`UX.md` section 3). The Text size setting scales every style.

92. Undo of a move puts the note back into its old folder at depth 1 with the same file name when it is free (`MoveNoteUseCase`). A note that came from a sub-folder does not go back into the sub-folder.
93. "Back up to" is saved when you press Enter, when you press "Back up now" and when Settings closes. An empty address turns the push off; versions are still kept.
94. The Settings General page keeps the quick note folder picker, which `UX.md` section 2 does not list: without it the quick note folder could only change in `spaces.json`.
95. `⌘↑` and `⌘↓` pick the previous and next note only while the note text is not being edited; in the text they keep their usual meaning (start and end of the text). `⌘⌥↑` and `⌘⌥↓` pick the note from anywhere. `⌘⌫` works the same way.
96. `⌘F` (Search) has no main menu item, because a menu item would take the key before the search field's own shortcut. Every other key of `UX.md` section 8 is in the main menu.
97. The README has a table of the four screenshots the owner takes; the files do not exist yet.

98. The main menu is set when Slate starts and again each time the panel opens, not only with the window. Slate has no Dock icon, so the menu is not visible in the panel, but its keys (`⌘Z`, `⇧⌘Z`, `⌘C`, `⌘V`, the Format keys) work there.
99. The editor keeps its own `UndoManager`. `RichTextView` answers `undo:` and `redo:` itself, so the Undo and Redo commands use the editor history and not the window's. After an undo the editor writes the Markdown again.

100. Sub-folders follow ADR 0011: any depth; a folder lists its sub-folders first, then only its own notes; the sidebar is a tree with a remembered open state. The owner first chose "a parent lists all notes below it" and changed it after a try to "own notes and sub-folders", like Finder. The folder count in the sidebar and on a sub-folder row is the number of notes in it and in all its sub-folders.
101. A sub-folder has no colour, icon or place of its own: it takes the colour of its top-level folder, an outline folder icon, and the name order. `.slate/spaces.json` does not change.
102. `ListSource.folder(FolderPath)` is the list of a sub-folder; `.space` stays for top-level folders, so `⌘1`…`⌘9` and the stored navigator state keep working.
103. Search in a sub-folder asks the index for the top-level folder and keeps the hits inside the sub-folder; the limit of 200 hits applies before that.
104. Deleting a top-level folder still moves every note in it, also from its sub-folders, to depth 1 of the quick note folder. Undo puts each note back at its old path and depth.

105. S5 uses the official MCP package `modelcontextprotocol/swift-sdk` 0.9.0. It builds with Swift 6.3.3 and the project settings, so the fallback server of ADR 0010 was not needed. Only `SlateCLI` and its tests depend on it.
106. Tool answers are JSON text (pretty printed, sorted keys); errors are one plain sentence with `isError`. Every call first runs the unchanged-files scan of the index, like the other CLI commands.
107. `read_note` returns the whole file and `hash` (SHA-256 of the file bytes). `update_note` takes the body only. When the agent sends the whole file back, the header part is dropped and the app's header is kept.
108. Every agent write takes a snapshot before the write (only when there are unsaved changes, with the usual `snapshot: N files` message) and one after it (`agent: <tool> <title>`, no push). So Restore can always go back to the state before the agent. When versions are off in the settings, no snapshot is taken.
109. The Activity line "Changed by an agent" crosses processes through `<support>/agent-changes.jsonl` (the last 200 changes; port `AgentChangeLog`). The app reads it after each change the watcher reports. It is not in the notes folder, so the storage format does not change for it.
110. `create_note` needs a folder that exists (top-level or sub-folder) and does not use a template: the body is what the agent sends, or empty. `attach_image` names the file `<stamp>-agent.<ext>`, takes the extension from the first bytes (not from the file name), puts the caption into the alt text and appends the image at the end of the note.
111. Permission rules (`AgentPermissions`): a listed folder allows its sub-folders; case does not matter; folders that start with `.` or `_` are never writable; `move_note` needs both the old and the new folder. Reading is allowed in every note. Path rules (`AgentPathPolicy`): relative paths or absolute paths inside the notes folder, never `..`, never `.`/`_` folders, only `.md` files at depth 1 or more.
112. The AI access box lists the top-level folders. Turning one on allows its sub-folders. A sub-folder written into `agents.json` by hand is kept and works, but has no switch.
113. The guide block is checked each time the app opens the notes folder, not only when the version changes: the app writes when the block differs from the current one. A file without markers gets the block at the end. If the owner deletes the block, it comes back at the next start.
114. The card is dragged with an `NSItemProvider` that carries the file URL for other apps and the internal `slate-note:<id>` text only for Slate (`visibility: .ownProcess`), so dropping on a folder still moves the note. Search result rows still drag the internal text only.
115. Copy Path and Copy Link in the Note menu have no keys: `⌥⇧⌘C` and similar are taken by the text system in many apps, and `UX.md` section 8 lists no key for them.

116. S6 tables follow ADR 0009 level 1. The model stores each cell as its inline Markdown (`TableCell.markdown`), not as attributed text, so an unchanged cell keeps its exact text. The block also keeps the source lines: an unchanged table is written back byte for byte, a changed one in the canonical form `| a | b |` with `---` markers (`:---` and so on as read).
117. A pipe table is read only when every row has as many cells as the header and every cell is inline text the editor can show. Otherwise the whole table stays a raw block (an image in a cell waits for S7).
118. No `BlockAttachmentKind` enum (ADR 0009 "Consequences"): `BlockKind.table` with `isAttachment` is enough, and nothing else would use the enum.
119. A cell edit is committed when the caret moves to another cell, when the table is left, before a structure change, on `flush()` (save, note switch, quit) and 2 s after the last key. Each commit is one undo step of the document. Inside a cell ⌘Z first undoes the typing in that cell.
120. Spreadsheet rows paste as plain text by default; Edit → Paste as Table (no key) turns tab-separated text, or a Markdown table, into a table. The M2 editor's "Paste as code" bar that ADR 0009 refers to no longer exists, so a menu command replaces the bar. A Markdown table on the pasteboard always pastes as a table.
121. The table view reserves 20 pt at the right and the bottom for the "+" strips, so there is a little more space after a table than after an image.
122. Enter and Tab at the end of the table add a row and stay in the table; ↑ in the header row and ↓ in the last row leave it. Return in a cell never makes a new line; a pasted new line becomes a space.
123. Deleting a table from the menu asks "Delete this table? Yes · No" inline when more than one cell has text (5 s, then it goes away). Backspace after a table removes it at once, like an image; Undo brings it back.
124. While a cell is edited, the format bar shows the state of the main text, not of the cell. Bold, italic, strikethrough and link from the bar and the menu act on the cell; other format commands leave the table first.
125. S7 started without the owner's check of S6, because the task asked for S5 to S7 in one run once S6 and its tests pass. `ROADMAP.md` says S7 waits for the owner; the owner can still reject S6 and S7 together.
126. A cell image is one U+FFFC with `slate.imagePath` and `slate.imageAlt` inside the cell text, and `![alt](path)` in the file. Only cells read inline images; a body paragraph with an inline image stays a raw block as before.
127. An image for a cell goes through the same import as the main text (`EditorHandlers.pasteFiles`, `pasteImage`, `requestScreenshot`). The controller remembers the cell (`imageTarget`); the next insertion from the store lands in that cell. When the cell is no longer being edited, the image is added at the end of its text. A space separates the image from text before it.
128. Thumbnails are 80 pt high with the image's shape and a 4 pt radius; a missing image shows as an empty 80 × 80 square. Wide images make the column wide; the column then shrinks like any other.
129. Pasting text into a cell pastes it as plain text on one line; Markdown copied from Slate keeps bold, italic, links and images.
130. A click on a table cell does not pass the mouse event to the cell's text view: forwarding it made `NSTextView` start its mouse tracking loop inside the table's `mouseDown`, and Slate hung at about 60 % CPU (the owner saw it on the first try). The table now puts the caret at the click point itself. Clicks inside the cell that is already being edited still go to the text view directly.
131. Several lines in a table cell follow ADR 0012: `<br>` in the file, U+2028 in the editor. `⇧Enter`, `⌥Enter` and `⌃Enter` add a line; Enter keeps moving down (ADR 0009). ↑ and ↓ stay in the cell while there is a line above or below the caret; a long line that only wraps on screen does not count. This replaces decision 122 for pasted text: lines stay lines.
132. The Quick Look panel opens one level above the highest visible Slate window. The menu bar panel sits at `.statusBar` level and the Quick Look panel at a lower level, so the preview opened under the panel and looked empty. A detached window was not affected.
133. Save to Downloads copies the image file through `NoteExporting.copyToDownloads`, the same place as the HTML and PDF export, and keeps the file name ("photo 2.png" when the name is taken). It does not open Finder, unlike decision 52: a toast is enough for one image. The hover button is only on images in the note text; a cell thumbnail is 80 pt high, so a cell image has the item in its right-click menu instead. A right click on a cell starts editing that cell, the same as a left click.
134. The arrow keys enter a table from the text around it. The editor lets the text view move the caret first; when the caret lands on the table paragraph, the table starts editing a cell instead. ↓ and → enter the header row, ↑ and ← the last row. ↑ and ↓ pick the column under the caret, → takes the first cell and ← the last cell with the caret at its end. Shift with an arrow still selects across the table.
135. Find in Note searches table cells. Slate runs its own `NSTextFinder` with a client that joins the text and the cells; a match never crosses a cell edge. `NSTextFinder` reads the text on a background queue, so the client keeps a copy under a lock and rebuilds it on the main actor. With incremental search the finder moves between matches without changing the selection; when the bar closes on a match in a cell, that cell starts editing with the match selected. Replace in a cell rewrites the cell through `TableCellText`, so its formatting stays.
136. Copy Table as Markdown puts the GFM table on the clipboard (the source when the table is unchanged). Copy Table as Text puts tab-separated text, one row per line, for Numbers, Excel and chat apps: no formatting, a line break in a cell becomes a space, images are left out. Both also put the Markdown under Slate's own clipboard type, so a paste into Slate gives the table back.
137. Text to table uses the Table command: with a selection it converts the selected paragraphs, without one it inserts an empty table. The column separator is a tab when any line has one, `|` when every line has one (a GFM delimiter line is dropped), otherwise there is one column. Blank lines are skipped, the first line becomes the header, and a single line gets an empty row. Inline formatting stays; headings, lists and quotes become plain cells. A selection with an image or a table in the middle is not converted. Convert to Text gives one body paragraph per row with tabs between the cells; the writer drops a tab at the end of a line, and cell images become image paragraphs under their row. Each direction is one undo step.
138. A wide table scrolls sideways inside its block. Columns shrink to fit the text width but not below 120 pt or their own text width; past that the view is as wide as the text and moves its bounds origin to show the rest. A swipe that is more sideways than up or down scrolls the table, any other scroll goes to the note. The cell being edited and a find match are scrolled into view. The bar under the table only shows the position.
139. Cell selection is a rectangle (`TableCellRange`: anchor and head) held by the table view; while it is shown the table view itself is the first responder and no cell is being edited. Every change on it goes through `change`, so each is one undo step. A copy of one cell puts only its inline Markdown on the clipboard, a copy of more cells a GFM table plus tab-separated text. A paste takes Slate's Markdown, a GFM table, tab-separated text or plain lines, and grows the table when the block does not fit. Bold and the other styles are added to every cell unless every non-empty cell already has them, then removed. Typing replaces the anchor cell, as in Numbers. A drag that starts inside the text of the cell being edited selects text, not cells (the text view runs its own mouse loop).
140. Image size follows ADR 0013: a `|width` suffix in the alt text, the Obsidian form. The reader and the writer did not change, so a file with `|300x200` stays as it is. An image with a width is not capped at 360 pt high. In the text there is a drag grip and a Size menu; in a cell only the Size menu, because a cell thumbnail is small and the drag would fight the cell's text editing. During a drag the image is resized on screen only; the file changes once, on mouse up.

141. Projects follow ADR 0014. A project is a top-level folder whose entry in `.slate/spaces.json` has a `project` object (`id`, `repositories`, `remote`), not a separate `projects.json`: the entry already moves with a rename, so no second file has to follow it. Make a Project keeps a chosen icon and sets `shippingbox.fill` only on a plain folder icon; Make a Folder sets the plain icon back. A new project adds the folder to the writable folders of `.slate/agents.json`; Make a Folder does not take that right away again.

142. The Files section reads the folder directly (`VaultFileStore.files(in:)`), not the index: files are not indexed. The watcher now reports every changed file under a folder, not only notes; temporary names (`.sb-`, `~`, `.tmp`, `.swp`, hidden names) are dropped, and the reindex still looks only at `.md` paths. A trashed file goes to the macOS Trash, not to Slate's Trash, because Slate's Trash and its list are built for notes; Undo moves it back.

143. A task is the folder plus the note with the same stem and `type: task`; when there is no such stem, the first task note directly in the folder counts. Status, ticket and branch show only inside projects (`TaskLineMapper` and the project list check the space), so a task note from the old `Tasks` folder looks as before. The status sort and pills come from `TaskStatusMapper`. The task template gained `## Log` at the end; it applies to every new task note, also outside projects.

144. Import Folder copies, it never moves: the source may be a work repository that the owner keeps as it is. Files already at the target are kept, hidden files and package contents are skipped. The repository is the first folder above the source (or the source itself) that holds `.git`.

145. S9: `slate mcp` reads its working directory once at start (`FileManager.currentDirectoryPath`, which is the directory Claude Code starts it in) and puts the project into the MCP `instructions`; `project_context` and `start_task` also take `path`, because a client may start the server elsewhere. MCP `roots` are not used yet: the swift-sdk server would have to ask the client after `initialize`, and the path argument covers the case. The project lookup order is: a linked path that holds the directory, the main checkout of a worktree, then the normalized remote (scheme, user, port, `.git` and case dropped).
146. S9: `add_file` copies a file from a path or from base64 with a name, at most 200 MB, into a folder agents may write; a taken name gets a number. `save_version` is a snapshot with the message `version: <name>` and no push. The registration line is now `claude mcp add -s user slate -- slate mcp` so every repository sees the server; the old local registration keeps working.

147. S10 follows ADR 0015 with one history repository, not one per project as the first plan said: Restore and the version list of a note that lived in an ordinary folder before it became a project stay in one place, and a list of changes of a folder is `git log -- <folder>`. Clear History of a folder rewrites the history in a temporary bare copy (`--no-local` clone, `filter-branch --index-filter`, fetch back, move the branch), because `filter-branch` in the repository itself removed the folder from the disk in a test. After any clear the next push uses `--force` once (a marker file in the history repository).
148. The large file limit is a constant, 50 MB, not a setting. Files above it are listed in `info/exclude` before every snapshot; a file that was already in the history stays tracked.

149. The own-write window of the watcher is 10 s, not 2 s. An event counts as Slate's own write only when the hash on disk equals the hash Slate wrote, so a longer window cannot hide an edit by another tool; under load FSEvents reported Slate's writes after more than 2 s. `externalEditArrivesAsAPathChange` writes the file up to three times, because under load the folder event of the setup can arrive with the first write and turn it into a rescan.

150. The folder tree is a `FolderTree` index (parent → sorted children), built once in `VaultStore` when the folders change, together with the Move to targets. Before, `FolderTreeMapper.children` filtered every folder for every node, and every note card built the whole Move to list: with 2,238 folders one card took about 30 s. Now the tree and the menus of 60 cards take 0.13 s in a debug build. Import Folder… of a folder that holds `.git` copies only `.md` files; `Pods`, `Carthage`, `node_modules`, `DerivedData` and `build` folders are always skipped.
151. Slate is one normal window with a Dock icon (ADR 0016). The close button and `⌘W` hide the window, the Dock icon, the menu bar icon and `⌥⌘N` show it on the current desktop (`moveToActiveSpace`), and the window is open or hidden at launch as it was at quit. The panel is gone; Quick note keeps its panel.
152. The link window (`LinkPopover`) has two fields: Text and Link to. `LinkAddress` turns the Link to value into the link: a note name from the list or any text that is not an address becomes `[[Note]]`, an address with a scheme or a path stays as it is, and `example.com/x` gets `https://`. The window takes the keyboard when it opens (`makeKeyAndOrderFront`, again after the run loop and in `popoverDidShow`): before, the first key went into the note, and the transient popover closed at once. The link bar (`LinkBar`) is a subview of the text view, like the image buttons. In a table cell the window is anchored to the cell editor; while it is open, `TableBlockView.textDidEndEditing` keeps the cell editing (`TableCellEditor.isEditingLink`), because removing the cell editor closes the popover.
153. Table grips (`TableGrip`, `TableLayout+Grips`) are drawn inside the cell padding, because the table view has room only at its right and bottom edge (the "+" strips). Moves are `TableModel.moveRows` and `moveColumns`; `TableModel.position(of:moving:to:)` maps the edited cell and the selection to their new place. A table change now reloads the edited cell from the model instead of writing the editor text into the old index, which put the old cell text into the moved row.
154. Slate activates itself with `NSApp.activate(ignoringOtherApps: true)` in `AppWindows` (the window, Settings, the return after a screenshot). The plain `NSApp.activate()` is a request that macOS refuses after a click on the status item, so the window opened behind the active app. The details are in `docs/PLAYBOOK.md` section 1.
155. `Scripts/install.sh` signs the installed app and the `slate` command with the local certificate from `~/.config/slate/sign-identity` (ADR 0003 amendment). Ad-hoc builds asked for Documents access after every install, because macOS ties permissions to the signature. The hash lives outside the repository, so no name is in it (ADR 0006).
156. Tests that wait for the file watcher first write a marker note and wait for its event (`sync` in `FSEventsVaultWatcherIntegrationTests`). FSEvents sends events in order, so a late event from the setup (the new `Inbox` folder, a `.rescan`) can no longer fall into the measured part. `waitUntil` waits up to 10 s instead of 2 s; it returns as soon as the condition holds, so a passing run is not slower. Before, these tests failed when `fseventsd` or a build kept the Mac busy.
157. Highlights and text colours are bits 8 to 11 and 12 to 15 of `InlineStyle`, not new attributes, so every place that keeps bold (typing attributes, cell editors, run merging, copy and paste) keeps colours with no extra code. The palettes are fixed (ADR 0017); a tag with another colour keeps the paragraph raw. `HighlightScanner` finds `==` pairs after the runs are read, using `SourceEscapes` to skip escaped `\=`. The writer opens the highlight first, then the text colour, then bold, italic and strikethrough. The display colours are cached, because a new dynamic `NSColor` is not equal to the old one and the styler would restyle the text on every pass.
158. Code colours come back from the M2 highlighter (`Highlighting/`, restored from commit `ad3de36^`): line by line regular expressions, so a `/* … */` comment over several lines is coloured only on its first line. `RichTextStyler.style` splits each attribute run at token edges and changes only pieces whose colour differs, so typing in a block does not restyle the whole block. The language label is drawn by `RichLayoutFragment`, and a click on it is found by `codeLanguageHit` before the checkbox and link checks.
159. Go to Heading is an AppKit menu built by the editor (`outlineMenu`), not a SwiftUI menu: it is fresh each time it opens and the same for the button and `⇧⌘O`. From the keyboard it opens under the caret, from the button near the top-right of the text. The jump scrolls the heading 16 pt under the top and calls `showFindIndicator`.
160. Backlinks are a capsule with a count in the title row and a popover, not a block under the text: a block inside the `NSTextView` scroll view needs its own layout below the text container, for the same information. `BacklinksStore` refreshes on index and vault events and on a note switch, but not on `.noteSaved`, because every autosave of the open note posts it. Markdown links to `.md` files are indexed as kind `note` by stem (`MarkdownNoteLinkPolicy`); `IndexSchema.version` is 2, so the index is rebuilt once.
161. Export uses the Data code that S1 left (`HTMLExporter`, `NoteExporter`). The port now takes the note's folder, so images are read from disk and put into the HTML as `data:` URLs. `ExportMarkdownPolicy` turns `[[links]]` into their text and `==x==` into `<mark>` before the HTML, outside code. The PDF prints a TextKit 1 `NSTextView` with `jobDisposition = .save` into a temporary file: `NSPrintOperation.pdfOperation` gave one tall page. The HTML importer of AppKit ignores margins on `pre`, so `spacingCodeBlocks` adds them after the import.
162. The folder column can be resized like the list (180 to 300 pt, default 220 pt, key `window.sidebarWidth`). The handle lies over the trailing 8 pt of the column, so the layout does not move. A folder name that does not fit shows the full name in the hint of the app (`hintWhenTruncated`), not in a system tooltip. The font stays the system size: a smaller font in only one column looks out of place next to the list, and the width now solves the problem.
163. Collapsed sections (like Apple Notes) live only in the editor: the file, the Markdown and the storage format do not change. Like Obsidian, Slate keeps them in its own settings (`editor.collapsedSections`: note id to a list of keys). A key is the heading level and title, with `#2` for the second heading of the same name (`SectionKeys`), so it survives edits and changes on disk; a key whose heading is gone is skipped. The editor reports keys through `EditorHandlers.collapsedSections` only after a fold, an unfold or an edit, never after it loads a note. The text stays in the text storage; `NSTextContentStorageDelegate.textContentManager(_:shouldEnumerate:options:)` skips the paragraphs of a folded heading, so TextKit 2 does not lay them out. TextKit 2 does not make a new layout fragment for an invalidated range, so the arrow state is set on the existing `RichLayoutFragment` of a heading before the layout is invalidated. The text view has a 16 pt side inset for the arrow; `EditorView` has 16 pt less padding, so the text stays in the same place. An edit that touches a folded section (a new line after the heading, a deletion into the section) opens it; the caret skips hidden text, and a selection inside it (Find) opens it. The shortcuts follow Xcode (`⌥⌘←`, `⌥⌘→`); inside a table cell the cell editor keeps them for moving columns.
164. The editor is more compact on the owner's request: body line height 1.25 (was 1.4) and paragraph spacing 5 (was 8), lists 1.2 and 2 (were 1.35 and 4), quotes 1.25 and 4, headings and code blocks a little closer. A picture of the same note is 13 % shorter. Export to PDF and HTML has its own styles and does not change.
165. Search marks are TextKit 2 rendering attributes (`addRenderingAttribute(.backgroundColor:)`), not text attributes: they never reach the file or Undo. Every search word of at least 2 letters is marked, case and accents ignored, like the first match that the caret goes to. Any edit, Esc and a new note remove them. Words inside table cells are not marked; Find in Note finds them. Find in Note keeps `⌥⌘F` and now has a button.
166. `⌘F` and `⌃F` depend on the focus, like in Apple Notes: when the first responder is inside the editor's scroll view (the text, a table cell or the find bar), they open Find in Note; elsewhere they focus the search field. The hidden `⌘F` button of the list asks `EditorStore.findInBody`, a closure that `EditorView` sets to `EditorCommands.findIfFocused`; `KeyboardMap` maps both keys to `.findInNote` too, so the result is the same whichever view gets the key first. `⌃F` no longer moves the caret one letter forward in the note (the Emacs key). `⇧⌘F` always searches all notes.
167. The find indicator of `NSTextFinder` (the yellow box over the current match) is empty unless the client draws the text: `NoteFindClient.drawCharacters(in:forContentView:)` draws each line piece of the match in black at its baseline (`TextSegmentRects.pieces`), without the paragraph style and the background, in the text view and in table cells.
168. `NoteListStore.sort` was written to `list.sort` but never read back, so every launch started with Date Edited; the init now reads it. The sort menu in the list header is the first UI for it. The sort is one setting for all lists, not one per folder; search results keep their own order.
169. A code block, a raw block or a quote is one paragraph that Enter does not leave, so at the edge of a note there was no place for the caret before or after it. The text storage has no trailing newline after the last block. `↑` on the first line and `←` at location 0 insert a body paragraph before such a block; `↓` on the last line and `→` at the end add a newline and make the empty tail a body paragraph. Tables, images and dividers already take typing before and after them, so they are left out.
170. The editor has 8 pt above the text and 96 pt below it. `NSTextView` has one vertical inset for both edges, so the inset is half of 104 pt and `RichTextView.textContainerOrigin` returns 8 pt for the top; the view grows by the rest at the bottom. The space is part of the text view, so a click there puts the caret at the end, unlike a scroll view content inset.
171. A list whose item has a child that is not a nested list (a table, a code block, a quote, a second paragraph) is read as one raw block, because the editor cannot write it back the same way (`ListReader` returns nil). An agent wrote a table indented under a numbered item with `batch_edit`, and the whole section showed as raw Markdown. The agent guide now forbids it; the reader stays strict, so the file never changes without a request.
172. Every `slate mcp` tool call is checked against the input schema of the tool in `MCPToolCatalog` before it runs (`MCPArgumentCheck`): unknown names, missing required names and wrong types go into one `AgentError.badArguments`, and the tool does not run. The schemas say `additionalProperties: false`. Each `batch_edit` operation is checked against the schema of its tool plus `tool`, `id`, `task` and `expectedHash`. The reason: `create_note` read only `body`, an agent passed `text`, and the tool made an empty note and answered with success. The catalog is the one list of names, so a tool can no longer read a name the catalog does not declare without a test failing. `create_note` and `update_note` answer with `lines`, the number of lines of the body, and `create_note` adds a `warning` for an empty body.
173. A table cell is read as a Markdown document of its own. A cell that starts with a block mark (`#`, `-`, `>`, `1.`, three backticks) became a heading, a list or a code block, and the whole table stayed raw. GFM cells hold only inline text, so `TableCellText.inline` now reads such a cell again with the mark escaped (`\#`, `1\.`). The cell source in the file does not change.
174. `slate mcp` runs as long as the agent session, and `install.sh` puts the new `slate` in place with `mv`, so an old server kept the old code. At start the server saves the file number and the date of its own file (`ExecutableStamp`, from `Bundle.main.executablePath`). Before each call it compares them with the file at the same path; a different file means a new install, and the call ends with `AgentError.serverOutdated`. All tools are refused, also the reading ones, so the agent sees the message at once. A version number was not used: a local build between installs has the same version.
175. The notes list hides with `WindowLayout.showsList` (key `window.list`). The list column stays in the view tree with zero width, no opacity and no hit testing, because the search field and the `⌘F`, `⌃F` and `⇧⌘F` shortcuts live in it; a search of all notes shows the list first. A new source (`noteList.source` changes, or a click on a folder in the sidebar) shows the list, so a click on a folder never looks like nothing happened. The list button sits over the top left of the editor (`PanelToggles`), in the 28 pt above the title, so the editor layout does not move.
176. Text that `append_to_note`, `attach_image` or `log_progress` adds at the end of a section starts after a blank line (`SectionAppendPolicy`). The only exception is a list item after a list, so a Log list stays one list. Before, the text was glued to the last line of the section, and an image after an `Answer:` line became part of that paragraph. Separately, the editor reads a paragraph with an image alone on one of its lines as text, image and text blocks (`MarkdownReader`), so a file written so by another tool shows the image and not a raw block. An image in the middle of a line still makes the paragraph raw.
177. A Log entry from `log_progress` or the daily log drops the blank lines of its text (`TaskLogPolicy`, `DailyPolicy`). An agent wrote "Done", "Left" and "Next step" as paragraphs with blank lines between them, so the list item had several paragraphs, and the editor showed the whole Log as a raw block (decision 171). Now the parts are lines of one item.
178. An image can sit under a list item (ADR 0018). In the editor it is an image block whose `indent` is the item level plus one and whose `group` is the group of the list (`BlockAttributes.isListImage`); it does not reset the list numbers, and the styler indents it to the item text. `ListReader` reads an image paragraph inside an item, and an image line glued to the item text; `ListWriter` writes a blank line, the image indented to the item text, and a blank line. An image added in the editor while the caret is in a list item goes under the item. `attach_image` takes `after` (`ImagePlacementPolicy`): the image goes under the one line with that text, its paragraph or its list item; the text is checked before the image is copied, so a wrong `after` leaves no file in `_attachments`.
179. A folder moves by drag and drop in the sidebar (`MoveFolderUseCase`, `FolderMovePolicy`). The drag carries `slate-folder:<path>` as plain text, visible only inside Slate, so a drop on the Projects label never imports it. A drop on a folder moves the dragged folder inside it; a drop on the "Folders" header makes it a top-level folder with a new entry in `spaces.json`. A top-level folder that moves inside loses its `spaces.json` entry; `FolderMove` keeps the entry and its position, so Undo puts back the colour, the icon and the place. The quick notes folder and projects refuse to move (`VaultError.defaultFolderMove`, `.projectMove`), because a project has its own history repository and repository links. The `_attachments` links of every moved note are rewritten for the new depth, as for a moved note. No storage format change.

## Next steps

1. The owner runs the manual checks below, first 40 to 48 for phase 3 in parallel and reports gaps; fixes come one numbered gap at a time.
2. M8 ideas only with a new ADR when they widen the v1 scope of ADR 0007.

## Manual checks (owner)

Run these on the Release build (`Scripts/install.sh`), in light and dark mode. Mark each item as passed, or add a numbered gap under Known gaps.

### S1 Simplify

1. A new notes folder (Settings → Choose another folder…, an empty folder) gets only `Notes/` with the welcome note, `_attachments/` and `.slate/spaces.json`.
2. No menu, panel, window, card or Settings page shows tasks, tickets, branches, status, Today, tags, saved searches, the palette, actions, export, Float on Top or the outline.
3. The status item: left click opens the panel; right click shows New Note, Quick Note, Open Window, Settings, Appearance, Quit.
4. Settings has two pages, General and Shortcuts. The New note shortcut has no keys until you set them.
5. `slate://open?title=Welcome%20to%20Slate` opens the welcome note; a title that does not exist says "Slate found no such note".

### S2 Folders and the soft look

6. "+ New folder" and `⇧⌘N` make "New folder" with the name selected; Enter keeps the name, Esc cancels.
7. Double-click a folder and rename it; the notes stay in it, links to them still work.
8. Right-click a folder: Colour changes the icon tint; Icon changes the symbol; Move up and Move down change the order. All of it is still there after a restart.
9. Delete a folder with notes: the row asks "Delete …? Its N notes move to Notes. Yes · No"; Yes moves the notes and shows a toast; Undo brings the folder and the notes back.
10. The quick note folder has no Delete in its menu.
11. Drag a note card onto another folder: the note moves there.
12. Drag the edge between the list and the note: the list width stays after a restart. `⌘0` hides the folders in the panel and in the window.
13. The cards, the selection, the empty folder ("Nothing here yet."), "Pick a note or press ⌘N." and the Trash look soft and rounded, with no lines between the columns.

### S3 Rich text editor

14. Open a note, press `⇧⌘T`, type a title, press Enter, type text, press `⌘B`, type a word, press `⌘B` again, add a checklist with `⇧⌘L`, add an image with `⇧⌘I`. Close the note. The file in Finder holds only the subset Markdown (`# `, `**`, `- [ ] `, `![](…)`).
15. Open the same note again: it looks the same.
16. A note with a table (write `| a | b |` lines in another editor) keeps the table, byte for byte, after you edit other text in Slate.
17. Every format bar button works and shows its hint with the shortcut; the active style is tinted; the style menu names the current style.
18. Every key of the Format menu works in the text.
19. Lists: Enter makes the next item; Enter on an empty item ends the list; Tab and `⇧Tab` indent and outdent; Backspace at the start of an item makes plain text. Typing "- ", "1. ", "[] ", "# " or "> " at the start of a line starts that style.
20. Click a round checkbox: it ticks, and the file has `- [x]`.
21. Images: paste a screenshot, drag a PNG from Finder, use the Image button and `⇧⌘S`. Each image is its own block with rounded corners. Double-click opens Quick Look. Right click has Quick Look, Open, Show in Finder, Copy Image.
22. `⌘K` on selected text asks for an address; `⌘`-click opens it. `⌘`-click on a note link opens that note.
23. `⌘Z` undoes every command above, one step at a time, in the panel and in the window; `⇧⌘Z` redoes it. `⌘Z` in the title field undoes the title.
24. Copy formatted text from Slate into Slate and into TextEdit; paste a part of a web page. The styles come along; the Markdown file stays clean.
25. Type fast in the 5,000-line note (`Packages/SlateKit/Tests/SlateEditorTests/Fixtures/LongNote.md` copied into the notes folder): no visible delay. Switch to another note right after typing: the last words are saved.
26. Type accents (`⌥E` then `e`) and with a Japanese input method: the text is correct.
27. "Saved" fades in at the top-right a moment after you stop typing.
28. Change a note in another editor while it is open in Slate: the text reloads; with unsaved changes the "Changed on disk" banner appears.

### S4 Polish

29. `⌃⌥Space` from Xcode: the rounded field appears and Xcode keeps the focus after Esc. Pick a folder in the chip; Enter saves there and the toast says "Saved to …".
30. Settings → General: enter a git address in "Back up to" and press "Back up now". With a reachable remote the toast says "Backed up"; with a wrong address it says the backup failed, and Activity has the reason.
31. Move a note with the card menu: the toast offers Undo, and Undo moves it back. Move to Trash: the toast offers Undo, and Undo restores it.
32. Every key of `UX.md` section 8 works in the window and appears in the main menu of the window (except `⌘F`, decision 96).
33. Esc in the search field clears the search; Esc never hides the window (ADR 0016).
34. Tab moves from the folders to the list, to the title, to the text, and the focus is visible.
35. Take the four README screenshots.

### Sub-folders (ADR 0011)

36. Sub-folders: right-click a folder, New folder inside, type a name, Enter. The folder opens, the sidebar shows it under its parent with an arrow on the parent. Make one more level inside it.
37. In a folder with sub-folders the list shows the sub-folder rows first and then only the notes of that folder. A click on a row opens the sub-folder; the back chevron goes up. "All notes" shows every note.
38. `⌘N` inside a sub-folder makes the note there (check in Finder). Drag a card onto a sub-folder row in the sidebar and in the list; use Move to in the card menu. A note with an image moved one level deeper still shows the image, and the file has `../../_attachments/…`.
39. Rename a sub-folder (double-click or the menu); the open list follows. Delete a sub-folder with notes: it asks first, the notes move to the parent, Undo brings the folder and the notes back. Close and open Slate: the open arrows in the sidebar are as you left them.

### S5 Agents (ADR 0010)

40. Run `Scripts/install.sh`, then `claude mcp add slate -- slate mcp`. In Claude Code ask "add a line to my note Groceries": it uses `append_to_note`, and the open editor shows the line within a second. Activity (Settings → Check-up) shows "Changed by an agent: Groceries"; the clock button shows the version `agent: append_to_note Groceries`, and Restore goes back.
41. Ask the agent to change a note in a folder that is off in AI access: it gets "Agents may not change notes in …", and nothing changes on disk. Ask it to update a note after you typed in it: it gets "The note changed since you read it, read it again."
42. Drag a card into Terminal: the path of the file appears. Drag it onto a folder in the sidebar: the note moves as before. Copy Path, Copy Link and `⌥`-click on the title copy the path or the `slate://` link; paste the link in Safari to open the note.
43. A new notes folder gets `CLAUDE.md` and `AGENTS.md` with the block. Write a line above the block in `CLAUDE.md`, quit and open Slate: the line is still there.

### S6 Tables (ADR 0009)

44. Insert a table with the Table button, fill four cells with Tab, make one word bold with ⌘B, add a column with the "+" strip on the right. Switch to another note: the file holds one table with `|`. Open the note again: it looks the same. ⌘Z undoes the last cell edit.
45. Open a note from Obsidian or GitHub with a table, change another paragraph: the table lines in the file stay exactly as they were.
46. Right click a cell: add and delete rows and columns, align a column. Delete Table on a filled table asks first. Arrow keys and Esc leave the table; long text wraps in a cell. Check light and dark mode.
47. Copy a table and paste it into a plain text editor: you get the Markdown table. Copy rows in Numbers, then Edit → Paste as Table.

### S7 Images in table cells

48. Drop an image from Finder on a cell, paste a screenshot into another cell, and use the Image button while a cell is active. Each shows a thumbnail; double-click opens Quick Look; select a thumbnail and press Delete. The file holds `![](../_attachments/…)` in the cells. Move the note into a sub-folder: the thumbnails still show.

### Line breaks in table cells (ADR 0012)

49. In a cell type a line, press ⇧Enter, type a second line: the row grows. The file has `line one<br>line two`. Open the note in Obsidian: the cell shows two lines.

### Images: Quick Look and Save to Downloads

50. In the menu bar panel double-click an image in the text and an image in a table cell: Quick Look shows the picture above the panel.
51. Point at an image in the text: a round button appears at its top right corner. Press it: the toast says "Saved … to Downloads" and the file is in Downloads. Press it again: the second copy gets " 2". Right click a cell thumbnail and choose Save to Downloads: the same.

### Tables, second round

52. Put the caret on the line above a table and press ↓: the header cell under the caret is being edited. Press ↓ until you leave the table, then ↑: you are in the last row. → at the end of the line before and ← at the start of the line after enter the first and the last cell.
53. Write a note with "milk" in the text and in a table cell. Press ⌥⌘F and type milk: both are highlighted. Press Enter to go between them, then Esc on the cell match: the cell is being edited with milk selected. Replace milk with bread in the find bar: the cell changes and keeps its bold.
54. Right click a table cell, choose Copy Table as Text and paste into Numbers: each cell lands in its own cell. Copy Table as Markdown and paste into a plain text editor: the `| … |` lines.
55. Type three lines with a tab between two words, select them and press the Table button: a table with a header. Right click it, Convert to Text: the lines come back with tabs. ⌘Z after each step goes back one step.
56. Make a table with eight columns of long text: it stays inside the note and the right edge is cut. Swipe sideways on it: the columns move, and the thin bar under it moves too. Tab through the cells: the cell being edited is always visible.
57. Shift-click from one cell to another: a rectangle of cells is tinted. Press Delete: they are empty, ⌘Z brings them back. Select two cells, ⌘C, select one cell elsewhere, ⌘V: both values land there. Select a column and press ⌘B: every cell is bold. Drag from one cell to another across the table: the same rectangle selection.
58. Point at an image in the text and drag the grip at its bottom right corner: the image gets narrower, and the file has `![|<width>](…)`. Right click it, Size ▸ Original Size: the suffix is gone. Right click a cell thumbnail, Size ▸ Large: the thumbnail is 200 pt wide and the cell has `![\|200](…)`. Open the note in Obsidian: both images have the same size there.

### Projects (ADR 0014)

59. Press + next to Projects, type MyApp and press Enter: the project shows under Projects with a box icon and opens. Right click it, Link Repository…, pick a code folder: the menu now says Change Repository…. Right click a folder, Make a Project: it moves to the Projects section and keeps its notes. Make a Folder moves it back. Settings → AI access shows MyApp as writable.

60. Drag a PDF and a PNG from Finder onto the list of a folder: an accent outline shows, then both are in a Files section under the notes, the PNG with a thumbnail. Double click the PDF: Quick Look opens. "…" → Rename, type a name without `.pdf`, press Enter: the file keeps `.pdf`. "…" → Move to Trash, then Undo in the toast: the file is back. In Terminal, `cp` a file into the folder: it shows up within a second.

61. Right click MyApp, New Task, type `ABC-123 Fix login`, Enter: the folder `ABC-123 Fix login` opens with its note, the note shows In progress, `ABC-123` and `feature/ABC-123-fix-login` under the title. Click the pill, choose In review: the file has `status: review`. Go up to MyApp: the task shows an orange In review pill above a Done task.

62. Make a folder `demo/.slate` in a git repository with a note and a PNG in a sub-folder. Projects + → Import Folder…, pick `demo/.slate`: a project `demo` opens, the toast says "Imported 1 note and 1 file into demo", the sub-folder and the PNG are there, Change Repository… shows in its menu, and search finds the note. `demo/.slate` is unchanged.

### Agents and projects (S9)

63. Run `Scripts/install.sh`, then `claude mcp remove slate` and `claude mcp add -s user slate -- slate mcp`. In a repository linked to MyApp (Link Repository…), start Claude Code and ask "start the task ABC-123 Fix login and note what you find": it calls `project_context` and `start_task`, and the task shows up in Slate within a second with In progress. Ask it to add a log file and to finish the session: the file is in the task's Files section and the Log has a dated entry. Start a new Claude Code session and ask "where did we stop?": it reads the log through `project_context`.
64. In the same repository run `slate project`, `slate task status ABC-123 review` and `slate task log ABC-123 "Next: tests"`: the pill turns orange and the Log has the entry. In a git worktree of the repository `slate project` names the same project.

### Versions (ADR 0015)

65. Change a note twice with a pause of ten minutes (or press Save Version between). Open the clock button: pick the older version, "Changes since" shows the new lines in green and the old ones in red; "Text" shows the old text. Type "before cleanup" and press Save Version: it shows in bold at the top.
66. Let an agent log progress in a task, then open the clock button in the list header of the project: the change says "Logged progress in …" with an Agent badge and names the note; click it and the note opens.
67. Replace a PNG in a task folder with another picture, wait for a version, then "…" → Versions… on the file: Quick Look of the older version shows the old picture; Restore brings it back.
68. In the Changes of a project, Clear History of MyApp… → Clear History: the list shows one version, the notes and files are still there, and the versions of notes in other folders are kept. Settings → General → Clear History…: each note has one version left.

### Code blocks and attached files

69. Copy one line of JSON such as `{"a":1,"b":[true]}` and paste it into a note: it shows as one code block with indented lines, and the file holds a ```` ```json ```` block. Paste a few lines of Swift: one code block. Paste two lines of plain text: two paragraphs.
70. Select some lines and press the `</>` button: they become one code block. Put the caret in the block and press it again: the lines are paragraphs again.
71. Press the paperclip button (or `⇧⌘A`), pick a PDF: the note gets a link with the file name, and ⌘-click on it opens the PDF.

### Several carets

72. Write three lines `abc`, put the caret after `a` and press `⌃⇧↓` twice: two more carets blink under it. Type `XY`: every line is `aXYbc`. Press `⌘Z` once: all three are `abc` again.
73. With three carets press `⌘→` and type `!`: each line ends with `!`. Press Backspace twice at the start of the lines: the lines are not joined. Press Esc: one caret is left, and Esc again goes back as before.
74. With three carets click somewhere, or press Enter, or press `⇧⌘H`: one caret is left and the action works as with one caret.
75. Three carets blink together. In a list of three items put carets in the second and third items and press Tab: both move in; ⇧Tab moves them back. In plain lines Tab puts a tab at every caret.

### Format JSON

76. Open the note with the JSON that was pasted line by line, select from `{` to the last `}` and press `⌥⇧⌘J`: one JSON code block with indented lines; the lines above and below stay. `⌘Z` brings the old lines back. Select a word and press `⌥⇧⌘J`: the toast "The selection is not valid JSON".

### Wide format bar

77. Make the window wide: Divider, Screenshot and Format JSON are buttons at the end of the format bar, with no "…". Make the window narrow, or hide the folders and make the list column wide: the three buttons go back into the "…" menu, and nothing is cut off.

### Small changes by agents

78. In Claude Code, in a repository with a task in Slate, ask the agent to mark one Plan step done and to change one row of a table. The agent uses `replace_in_note` or `update_section`, not `update_note`. Open the note in Slate: only those lines changed, and the versions show "Changed" with the agent badge. Ask it to add a line at the top of a changelog section: the line is first.
79. Ask the agent to mark the first Plan step done: it calls `set_plan_item`, and the next `project_context` shows `done: 1` and the next step. Ask for three changes at once: one `batch_edit` call, and the versions of the note show one agent version, not three.

### Slate as a window

80. The Slate icon is in the Dock and in ⌘-Tab. Press Attach file and move to the file chooser: the Slate window stays. Choose a file: it is attached.
81. Press the close button or `⌘W`: the window goes away, the previous app gets the focus, and Slate stays in the Dock. Click the Dock icon: the window comes back with the same folder and note.
82. Leave the window on desktop 1, move to desktop 2 and click the menu bar icon (or press `⌥⌘N`): the window comes to desktop 2, and macOS does not switch back to desktop 1. Click the icon again: the window hides.
83. Hide the window and quit Slate from the menu bar menu, then open Slate again: only the icons show. Show the window and quit: at the next launch the window opens.
84. Click in the Terminal, then click the menu bar icon: the Slate window opens in front of the Terminal and takes the keyboard. Do the same with Settings… from the right-click menu of the icon.
85. Allow the access to Documents once after an install. Make a commit on `main` (the next install): Slate opens without asking again.

### Links

86. Select a word, press `⌘K` and type an address at once: the letters go into the Link to field, not into the note. Enter makes the link.
87. Click in a link: a small bar under it shows the address (or the note name) with Open, Edit, Copy and Remove. Edit opens the link window with the text and the address; change the text and press Enter: the link shows the new text.
88. In the link window, type the start of a note name: the field completes it from the notes list. Save: the link is `[[Note|text]]` in the file and `⌘`-click opens the note. Right-click a link in the text and in a table cell: the menu starts with Open Link, Edit Link…, Copy Link Address and Remove Link. Click a link in a table cell and press `⌘K` (or the Link button, which is active in a cell): the link window opens with the cell link and stays. Change the address and press Enter: the cell link changes.

### Table rows and columns

89. Move the pointer over a table: the row under it shows a small grip at its left edge, the column one at its top. Near the left edge, on the line between two rows, a round "+" shows; click it: an empty row appears there with the caret in it. The same at the top edge between two columns.
90. Drag the grip of a body row up or down: an accent line shows the place, and the row moves there. Drag a column grip sideways: the column moves with its alignment. The header row has no grip.
91. Click a grip: the row or the column is selected and the menu opens with Move Row Up and the other items. In a cell, `⌥⌘↑` and `⌥⌘↓` move the row and the caret stays in the same cell text; `⌥⌘←` and `⌥⌘→` move the column. Undo puts it back.

### Highlights and text colours (ADR 0017)

92. Select a word and press `⇧⌘E`: it gets a yellow background. Press `⇧⌘E` again: the background goes. Open the file in a text editor: `==word==`.
93. Select a word, open the colour button in the format bar and pick Green under Highlight, then Red under Text Colour: the word is red on green. The right-click menu shows a check next to Green and Red.
94. Do the same in a table cell, and in light and dark mode: the colours are readable in both.
95. Open the note in Obsidian: the yellow, green and red show there too.

### Code colours

96. Paste Swift code into a code block, then click "Plain text" in its top-right corner and pick Swift: keywords, strings and comments get colours, and the file has ```` ```swift ````.
97. Type in the block: the colours follow as you type. Pick Plain text: the colours go and the fence has no language.

### Go to Heading

98. In a long task note press `⇧⌘O`: the headings show under the caret, the current section is ticked. Pick Log: the view scrolls to it and it flashes. The list button next to the title opens the same menu.

### Backlinks

99. Open a note that other notes link to with `[[Name]]` or `[text](Name.md)`: a "↩ N" capsule shows next to the title. Click it: the notes and the line around each link show; a click opens that note.
100. Add a link to this note in another app (for example in Obsidian): within a few seconds the count grows.

### Export

101. Open a note with an image, a table and a highlight, click the share button next to the title and pick Export as PDF: Finder shows the PDF in Downloads, with the image, the table and pages. Do the same with Export as HTML and open the file in Safari, then move it to another folder: the image still shows.

### Sidebar width

102. Drag the right edge of the folder column to the right: the column grows up to 300 pt, and long folder names show in full. Quit and open Slate: the width stays. Double-click the edge: the column is 220 pt again. Rest the pointer on a name that ends in "…": a hint shows the full name. A name that fits shows no hint.

103. Open a folder with a long name, for example a task folder, so that its title above the list ends in "…". Rest the pointer on the title: a hint shows the full name.

### Collapsed sections

104. In a note with a few headings, rest the pointer on a heading: a down arrow shows on its left. Click it: the text under the heading hides, up to the next heading of the same or a higher level, and the arrow points right. Click again: the text is back. The file on disk does not change. Collapse a section, open another note, then come back: the section is still collapsed. Quit Slate and open it again: the same.
105. Put the caret in a section and press `⌥⌘←`, then `⌥⌘→`. Press `⇧⌥⌘←`: every section collapses; `⇧⌥⌘→` opens all. The same commands are in the Edit menu.
106. Collapse a section, put the caret at the end of its heading and press Enter: the section opens. Collapse it again and press `→`: the caret jumps over the hidden text. Search in the note (`⌥⌘F`) for a word in a collapsed section: the section opens.

### Compact text

107. Open a long note with paragraphs, lists, a quote and a code block: the lines and paragraphs are closer than before, the text is still easy to read, list markers and checkboxes sit on their lines, and the caret has the height of the line.

### Search marks and Find in Note

108. Search for two words, open a hit: both words are yellow everywhere in the text, and the caret is at the first one. Type a letter or press Esc: the marks go away. Check the colour in the dark theme too.
109. Click the magnifier next to the note title: the find bar opens over the text with the caret in its field; type a word: every match is marked, and Enter goes to the next one.
110. Click into the note text and press `⌘F`: the find bar of the note opens. Do the same with `⌃F`. Click a note card in the list and press `⌘F`: the caret goes to the search field above the list. In the note text press `⇧⌘F`: the search field too.
111. Find a word in a code block and in normal text with the find bar: the yellow box over the current match shows the word in black, in the same place as the text under it.

### Sort the list

112. Open a folder, click the arrows next to its title and pick Title: the notes are in A to Z order, pinned notes first. Pick Date Created, then open another folder: it uses the same order. Quit Slate and open it again: the order stays.

### Leave a block at the edge of a note

113. Make a note that starts with a code block. Put the caret on its first line and press `↑`: an empty line opens above the block; type there. Do the same at the end with `↓` on the last line of a code block that ends the note.

### Space below the text

114. Open a long note and scroll to the end: there is 96 pt of empty space under the last line. The first line still starts right under the format bar. Click in the empty space: the caret goes to the end.

### Strict tool arguments

115. In Claude Code, ask the agent to call `create_note` with the text under `text`. The tool answers with an error that names `body`, and no note appears in Slate. Then a correct `create_note` answers with `lines` equal to the number of lines of the text.

### Table cells with a mark

116. Open a note with a table whose first column title is `#`, or type `# 1` or `- a` in a cell: the table shows as a table, not as raw text.

### Old MCP server

117. Start a Claude Code session that uses Slate, then commit to `main` (the install runs). Ask the agent to read a note: it gets "Slate was updated after this session started…". Run `/mcp`, slate, Reconnect: the next call works.

### Hide the columns

118. Click the sidebar button in the Folders header: the folders hide, and the list header starts with the same button. Click the list button at the top left of the note: the list hides. With both hidden, both buttons sit after the window buttons. `⌘0` and `⌥⌘0` do the same, also from the View menu. Quit and open Slate: the columns stay as they were. Hide the list, press `⇧⌘F`: the list comes back with the search field active.

### Text added to a section

119. Ask an agent to add an image to a section whose last line is text (`attach_image` with `section`). The image shows under the text as an image, with a blank line before it in the file. Ask it to add a line to a Log list with `log_progress`: the list stays one list. Open a note where an image line follows a text line with no blank line: the text and the image show, not a pink raw block.

120. Ask an agent to call `log_progress` with a text of several paragraphs. The Log shows each entry as one list item with several lines, not as a pink raw block.

### Images inside lists (ADR 0018)

121. In a numbered list, put the caret in item 1 and add an image (format bar or paste). The image shows under item 1, indented to its text, and the next item is still 2. Press Return after the image: a new item 2 starts, and the old 2 becomes 3. Open the file in another editor: the image line is indented under item 1, with blank lines around it.
122. Ask an agent to add a screenshot under a list item with `attach_image` and `after`. The image shows under that item, and the list stays one list.
123. Drag a sub-folder onto another folder in the sidebar: it moves inside with its notes, the open note keeps its images, and Undo in the toast moves it back. Drag a top-level folder with a colour into another folder, then Undo: the colour, the icon and the place come back. Drag a sub-folder onto the "Folders" header: it becomes a top-level folder. Drag Inbox (the quick notes folder) or a project onto a folder: the toast says why it stays.

## Known gaps


- Tables, second round: a drag that starts in the text of the cell being edited selects text only; start the drag on another cell or use Shift-click.

- S2: a text file dropped on the list does not make a note yet (`UX.md` section 6). Folders reorder with Move up and Move down, not by drag.
- The agent did not run the manual checks. A scripted click opens the panel but does not make Slate the active app, so scripted keystrokes go to the frontmost app (a few of them went to the Terminal during this session). The borderless panel also hides its content from the Accessibility API.
- No `⌘⇧M` move picker. Move to is in the card menu, and cards can be dragged onto a folder.
- Esc closes the panel from the list and from the note text (S4); the search field clears on Esc first. The agent tested the editor part only in a test window.
- Capture (M4): the field does not take pasted images or files yet (`SPEC.md` 3.4). The agent did not test that the source app keeps the focus; scripted key presses do not reach the panel (first gap above).
- Search (M3): no progress bar or "Indexing 3,120 of 10,000" line during the first full scan (`UX.md` section 5). The list fills as the scan runs.
- History (M5): the first snapshot of a large folder runs at launch in the background and can take seconds. Every snapshot walks the notes folder once to find files over 50 MB.
- Quit waits up to 3 s for the save and the last snapshot; a slow push is cut off and runs at the next snapshot.
- `.claude/skills/add-feature`, `add-use-case`, `build-and-run` and `update-docs` and the example in `.claude/rules/presentation.md` still show DevHub features.
- Dark mode pass (M7) was done by reading the code: every colour is a `Theme` token, a `Tint` or a system colour, and the editor uses dynamic `NSColor`s. Nothing was looked at on screen.
- The main menu (M7) appears only while the main window is open, because Slate has no Dock icon otherwise.
- Previews in package files were not opened in Xcode yet.
- Editor (S3): the agent checked the editor with tests in a window and with offscreen pictures, not by typing in the running app. Input methods (accents, Japanese), spell checking, drag and drop from Finder and the paste of web pages need a check by hand.
- Editor (S3): in one offscreen picture of the whole window the list, quote and image buttons of the format bar looked faded while the others did not. The picture of the editor alone looked right. Check it on screen.
- Editor (S3): typing latency was measured by a test on the 5,000-line fixture (1.3 ms median, open 120 ms), not with Instruments. Markdown for a long note is written 250 ms after the last key (decision 88).
- Editor (S3): images have no resize handle; the right-click menu has no Remove (Backspace removes, Undo brings back).
- Editor (S3): a pasted URL is not turned into a link with a title (P1). There is no hover preview of a link.
- S5: the agent did not run Claude Code against `slate mcp`. A stdio test sent `initialize`, `tools/list`, `tools/call create_note` and `resources/list` and got the right answers; the tools are tested over a temporary notes folder.
- S5: a card dropped into the note text of Slate now gives the editor a file, so the editor adds a link to a copy of the note file in `_attachments/` instead of the text `slate-note:<id>`. Neither is useful; a drop of a card into the text should make a link to the note.
- S5: the Activity line of an agent change can come late when the watcher reports the file before `slate mcp` wrote its change line; it then shows with the next change. `⌥`-click on the title was not tried on screen: a text field may take the click first.
- S9: the agent ran `slate mcp` over stdio in a temporary repository (instructions name the project, `start_task` and `project_context` answer), not a real Claude Code session; manual check 63 is that run.
- S9: `project_context` sent in the same batch as `start_task` can answer before the task exists, because the server answers requests in parallel (next gap). Claude Code waits for each answer, so this matters only for scripts.
- S5: the MCP server answers requests in parallel. Two writes to the same note at the same moment are safe (the save checks the hash), but the second may fail with "The note changed since you read it".
- S6: the agent checked tables with editor tests, a throwaway XCTest in a window (the view is hosted by TextKit, the focus stays while a row grows) and offscreen pictures, not by typing in the running app.
- S6: accessibility shows the table as one element with a label ("Table, 3 rows, 2 columns"); rows and cells are not exposed yet.
- S7: drop, paste and Quick Look in a cell were tested through the controller, not with a real drag or a real double-click. Thumbnails cannot be resized, and a thumbnail is not selected by a single click (use Shift-arrow in the cell).
- S6: no manual column resize (ADR 0009 level 1). A wide table scrolls sideways (decision 138), but there is no drag on the scroll bar: it only shows the position.
- Sub-folders (ADR 0011): no drag of a folder into another folder, no colour, icon or manual order per sub-folder, no `⌘1`…`⌘9` for sub-folders. Esc does not go up to the parent folder yet; the back chevron does.
