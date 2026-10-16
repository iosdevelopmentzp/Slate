# Status

Last updated: 2026-10-16

## Stage

M3 done (index and search). Manual checks of M1, M2 and M3 by the owner still open. On first launch Slate asks for the notes folder (default `~/Documents/Slate`) and prepares it: six folders, `_attachments/`, `_templates/`, `.slate/` with `spaces.json` and the five note types, and a welcome note. Notes are real Markdown files with the header of `STORAGE-FORMAT.md` section 2. The list is built by a full scan at launch and kept current by the FSEvents watcher. 222 tests in 57 suites pass. Next: milestone M4 (capture and tasks).

## Screens

| Screen | State | Notes |
|---|---|---|
| First launch | real | "Where should Slate keep your notes?", the default path, Choose…, Start. A folder that cannot be prepared shows the reason under the path |
| Panel | real | Header: folder menu (All notes, folders, Trash, Sort by), title search (`⌘F`), New (`⌘N`; the menu offers Note, Task, Snippet, Meeting), Open as window (`⌘⇧O`). Footer: note count and "saved just now". No Settings button yet (H1, M4) |
| Window | real | The panel plus a sidebar: Folders with counts, New folder (+), Tags with counts (click searches `tag:`), Trash. Right click on a folder: Rename, Icon, Move up, Move down. `⌘0` hides the sidebar. No Saved searches yet (C9, M6) |
| Capture field | planned | M4 |
| Note list | real | Rows: status dot, kind icon for non-plain notes, title, relative date, pin, preview, badges (ticket, subfolder, images and files, open checkboxes). Hover and right click: Pin, Move to, Duplicate, Archive, Move to Trash (inline confirmation, toast with Undo). Badges come from the in-memory index |
| Trash | partial | Lists trashed notes with their folder and age, Restore on hover. No "Delete now" and no auto-empty yet (F4, M5) |
| Editor | real | Title field, chips, autosave, the "Changed on disk" banner (M1). Markdown styling with visible marks, code blocks with highlighting and a Copy button, checkboxes, list editing, images under their line, paste rules with the "Paste as code" bar, screenshots, `⌘`-click links (M2). `[[` completes note names, `#` completes tags; a link to a missing note makes that note; tag chips under the title search the tag (M3). No link titles (P1), no hover preview of a link target, no journal (M5) |
| Search | real | The header field searches titles, text, tags and tickets in the current folder ("Search all notes" widens it) with the filters of `SPEC.md` 6.1. Title matches show at once; the index answers within 80 ms plus the query. Rows show the snippet with the words in bold; Enter or a click opens the note with the caret on the first match. Esc clears. No palette yet (A7, M6) |
| Settings | planned | M4 (H1) |

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
25. Branches during the long build: one branch per milestone, each made from the one before (`m1.5-editor-spike`, `m2-editor`, `m3-index-and-search`, …). Merging the last one brings all of them.
26. M2 editor details: a tag needs at least one letter (`#123` stays text, it is the issue pattern of `links.json`). Tab indents a list item by the width of its own marker plus one space (`- ` two spaces, `1. ` three). Remove Image deletes the line (Undo brings it back); the file stays in `_attachments/` until "Clean attachments" (M5). The "Paste as code" bar lives inside `SlateEditor`, so Enter and Esc reach it while the text has focus.
27. The host gives text to the editor with `EditorInsertion(token:markdown:)`, like `EditorFocusRequest`; the editor inserts it on its own line once per token. `ARCHITECTURE.md` section 6.1 had an `EditorCommands` object; the token value replaced it, so no store holds an AppKit object.
28. `PasteKindPolicy` of `ARCHITECTURE.md` section 4.4 is `PasteClassifier` inside `SlateEditor`; the CLI and the use cases do not need it. `ARCHITECTURE.md` now says so.
29. The panel hides for a screenshot through `PanelVisibility` (two closures that `AppWindows` sets); the window stays. Quick Look runs through the `WorkspaceOpening` port with a `QLPreviewPanel` data source in `SlateData/System`.
30. M2 is two commits: the editor module (D1, D2, D3, D5 styling), then attachments, paste and screenshots (D4, B4, B5), because the handlers for D4, B4 and B5 share one change to `EditorStore`.

## Next steps

1. Owner: run the M1 manual checks (below). Merge the branch `m1-vault-and-notes` when they pass.
2. Owner: run the M2 and M3 manual checks (below).
3. M4: capture and tasks. Read `PLAYBOOK.md` sections 1, 2, 3 and 8 first.

M3 manual checks for the owner:

1. Run `Scripts/generate-vault.sh /tmp/slate-10k 10000`, then `SLATE_PERF_VAULT=/tmp/slate-10k swift test --package-path Packages/SlateKit --filter IndexPerformanceTests`. The line `index timing:` shows the full scan (budget 20 s) and the search (budget 50 ms).
2. In the panel, type two words of an old note in the search field. Results show with the words in bold; Enter opens the note at the first match.
3. Type `type:task status:active` and `tag:` with one of your tags.
4. In a note, type `[[` and pick a note from the list; `⌘`-click the link. Type `[[A new name]]` and `⌘`-click it: the note is made.
5. Rename a note that three other notes link to. The toast says three notes were updated; open them and check the links.
6. Type `#` and a letter: the list offers your tags. In the window, the sidebar lists the tags with counts.

M2 manual checks for the owner:

1. Open a note and type `# Title`, `**bold**`, a list, `- [ ] task` and a code block with ```` ```swift ````. The marks stay visible in a lighter colour and the code is coloured.
2. Click a checkbox. The file in Finder has `[x]`.
3. Press `⌘⇧S`, drag over a region. The panel hides and returns; the image shows in the note and the file is in `_attachments/`. The first time, macOS asks for Screen Recording: allow Slate in System Settings → Privacy & Security → Screen Recording, restart Slate, try again. Note what happens after a rebuild in `docs/STATUS.md` (`PLAYBOOK.md` section 11).
4. Copy a stack trace and press `⌘⇧V`: a code block. Paste it with `⌘V`: the bar asks; Enter makes a code block.
5. Hover a code block and press Copy.
6. Copy an image in Preview and paste it into a note.

M1 manual checks for the owner:

1. Run `Scripts/run.sh`. The first launch window appears. Press Start. `~/Documents/Slate` now has the six folders and `Inbox/Welcome to Slate.md`.
2. Open the panel. Press `⌘N`, type a title, press Enter, type a line. Within one second the file is in Finder with a header (`id`, `title`, `type`, `created`, `updated`).
3. Change the title in the title field and press Enter. The file in Finder has the new name.
4. In Finder, make a new `.md` file in `Inbox`. It appears in the list. Edit it in TextEdit and save: the open note reloads.
5. Type in a note, and at the same time change the same file in TextEdit. The "Changed on disk" banner appears; Keep mine and Take theirs both work.
6. Pin, Move to, Duplicate, Archive and Move to Trash from the row menu; Undo in the toast; Restore from the Trash.
7. In the window: New folder, Rename, Move up and Icon on a folder. Make a folder in Finder: it appears in the sidebar.
8. Type, then quit with `⌘Q` within half a second: the text is in the file.

## Known gaps

- The agent did not run the manual checks. A scripted click opens the panel but does not make Slate the active app, so scripted keystrokes go to the frontmost app (a few of them went to the Terminal during this session). The borderless panel also hides its content from the Accessibility API.
- No shortcut for Move to Trash: `⌘⌫` would take the key from the editor text. No `⌘⇧M` move picker. Both are in the row menu.
- No drag of a row onto a folder (C8 part). Moving works from the row menu.
- No way to delete a folder.
- Esc does not close the panel yet (`UX.md` section 6). The search field clears on Esc.
- The status chip is not a menu yet, and the ticket and branch chips have no actions (C3, M4).
- Changing the notes folder needs `defaults delete local.slate.app vault.path` until Settings (H1, M4).
- Search (M3): no progress bar or "Indexing 3,120 of 10,000" line during the first full scan (`UX.md` section 5). The list fills as the scan runs.
- Search (M3): typing `#` offers tags only after one letter, so `#` alone at the start of a line stays a heading.
- Crash safety is the 500 ms autosave and the save on quit. The journal comes in M5.
- The list column uses `HSplitView` (240 to 400 pt); its width is not saved.
- `ActivityRecorder` and `ShellRunner` have no user yet (M5 git history).
- `.claude/skills/add-feature`, `add-use-case`, `build-and-run` and `update-docs` and the example in `.claude/rules/presentation.md` still show DevHub features.
- Editor (M2): no title fetch for a pasted URL (P1); no hover preview of a link target; file links show as coloured links, without an icon, and cannot be dragged out to Finder; the language of a code block shows on its fence line, not as a separate label; Remove Image does not ask first (Undo works).
- Editor (M2): typing latency was measured by a test on the 5,000-line fixture (2.2 ms median), not with Instruments. The Screen Recording prompt of `PLAYBOOK.md` section 11 was not checked by the agent.
- Previews in package files were not opened in Xcode yet.
