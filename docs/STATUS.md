# Status

Last updated: 2026-10-17

## Stage

Phase 2 on branch `phase2-simple-v1`. **S1 Simplify, S2 Folders and the soft look, S3 the rich text editor and S4 Polish are built.** Next: the owner runs the manual checks below; every item passes or becomes a numbered gap. M0 to M7 stay in `main` (commit `545e0d6` is the last commit before S1 and holds every removed view).

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

## Next steps

1. The owner runs the manual checks below and takes the README screenshots.
2. Fix what the checks find, one numbered gap at a time.
3. Then M8 ideas (`docs/ROADMAP.md`), each only with a new ADR if it changes the v1 scope of ADR 0007.

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
32. Every key of `UX.md` section 8 works in the window and in the panel, and appears in the main menu of the window (except `⌘F`, decision 96).
33. Esc in the note text of the panel closes the panel.
34. Tab moves from the folders to the list, to the title, to the text, and the focus is visible.
35. Take the four README screenshots.

### Sub-folders (ADR 0011)

36. Sub-folders: right-click a folder, New folder inside, type a name, Enter. The folder opens, the sidebar shows it under its parent with an arrow on the parent. Make one more level inside it.
37. In a folder with sub-folders the list shows the sub-folder rows first and then only the notes of that folder. A click on a row opens the sub-folder; the back chevron goes up. "All notes" shows every note.
38. `⌘N` inside a sub-folder makes the note there (check in Finder). Drag a card onto a sub-folder row in the sidebar and in the list; use Move to in the card menu. A note with an image moved one level deeper still shows the image, and the file has `../../_attachments/…`.
39. Rename a sub-folder (double-click or the menu); the open list follows. Delete a sub-folder with notes: it asks first, the notes move to the parent, Undo brings the folder and the notes back. Close and open Slate: the open arrows in the sidebar are as you left them.

## Known gaps

- S2: a text file dropped on the list does not make a note yet (`UX.md` section 6). Folders reorder with Move up and Move down, not by drag.
- `FSEventsVaultWatcherIntegrationTests.externalEditArrivesAsAPathChange` failed once in a full run before S1 started (timing under load) and passes alone. Watch it.
- The agent did not run the manual checks. A scripted click opens the panel but does not make Slate the active app, so scripted keystrokes go to the frontmost app (a few of them went to the Terminal during this session). The borderless panel also hides its content from the Accessibility API.
- No `⌘⇧M` move picker. Move to is in the card menu, and cards can be dragged onto a folder.
- Esc closes the panel from the list and from the note text (S4); the search field clears on Esc first. The agent tested the editor part only in a test window.
- Capture (M4): the field does not take pasted images or files yet (`SPEC.md` 3.4). The agent did not test that the source app keeps the focus; scripted key presses do not reach the panel (first gap above).
- Search (M3): no progress bar or "Indexing 3,120 of 10,000" line during the first full scan (`UX.md` section 5). The list fills as the scan runs.
- History (M5): no diff view and no preview of a version before Restore (Appendix B). The first snapshot of a large folder runs at launch in the background and can take seconds.
- Quit waits up to 3 s for the save and the last snapshot; a slow push is cut off and runs at the next snapshot.
- `.claude/skills/add-feature`, `add-use-case`, `build-and-run` and `update-docs` and the example in `.claude/rules/presentation.md` still show DevHub features.
- Dark mode pass (M7) was done by reading the code: every colour is a `Theme` token, a `Tint` or a system colour, and the editor uses dynamic `NSColor`s. Nothing was looked at on screen.
- The main menu (M7) appears only while the main window is open, because Slate has no Dock icon otherwise.
- Previews in package files were not opened in Xcode yet.
- Editor (S3): the agent checked the editor with tests in a window and with offscreen pictures, not by typing in the running app. Input methods (accents, Japanese), spell checking, drag and drop from Finder and the paste of web pages need a check by hand.
- Editor (S3): in one offscreen picture of the whole window the list, quote and image buttons of the format bar looked faded while the others did not. The picture of the editor alone looked right. Check it on screen.
- Editor (S3): typing latency was measured by a test on the 5,000-line fixture (1.3 ms median, open 120 ms), not with Instruments. Markdown for a long note is written 250 ms after the last key (decision 88).
- Editor (S3): a code block has no language label and no colours; the language is kept in the file. Images have no resize handle; the right-click menu has no Remove (Backspace removes, Undo brings back).
- Editor (S3): a pasted URL is not turned into a link with a title (P1). There is no hover preview of a link.
- Sub-folders (ADR 0011): no drag of a folder into another folder, no colour, icon or manual order per sub-folder, no `⌘1`…`⌘9` for sub-folders. Esc does not go up to the parent folder yet; the back chevron does.
