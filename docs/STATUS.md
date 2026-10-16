# Status

Last updated: 2026-10-16

## Stage

M1.5 done (editor spike: own core chosen). M1 manual checks by the owner still open. On first launch Slate asks for the notes folder (default `~/Documents/Slate`) and prepares it: six folders, `_attachments/`, `_templates/`, `.slate/` with `spaces.json` and the five note types, and a welcome note. Notes are real Markdown files with the header of `STORAGE-FORMAT.md` section 2. The list is built by a full scan at launch and kept current by the FSEvents watcher. 222 tests in 57 suites pass. Next: milestone M2 (editor v1).

## Screens

| Screen | State | Notes |
|---|---|---|
| First launch | real | "Where should Slate keep your notes?", the default path, Choose…, Start. A folder that cannot be prepared shows the reason under the path |
| Panel | real | Header: folder menu (All notes, folders, Trash, Sort by), title search (`⌘F`), New (`⌘N`; the menu offers Note, Task, Snippet, Meeting), Open as window (`⌘⇧O`). Footer: note count and "saved just now". No Settings button yet (H1, M4) |
| Window | real | The panel plus a sidebar: Folders with counts, New folder (+), Trash. Right click on a folder: Rename, Icon, Move up, Move down. `⌘0` hides the sidebar. No Tags or Saved searches yet (M3, P1) |
| Capture field | planned | M4 |
| Note list | real | Rows: status dot, kind icon for non-plain notes, title, relative date, pin, preview, badges (ticket, subfolder, images and files, open checkboxes). Hover and right click: Pin, Move to, Duplicate, Archive, Move to Trash (inline confirmation, toast with Undo). Badges come from the in-memory index |
| Trash | partial | Lists trashed notes with their folder and age, Restore on hover. No "Delete now" and no auto-empty yet (F4, M5) |
| Editor | partial | Title field (Enter, focus loss or 1.5 s renames the file), chips (kind, ticket, status, folder, subfolder, tags, read-only details), plain `MarkdownEditorView`, autosave after 500 ms, save on note switch, panel close, window close and quit. A new untitled note takes its title from the first line until the title is typed. A small "Changed on disk" banner with Keep mine and Take theirs. No styling (M2), no journal (M5) |
| Search | partial | Filters the loaded list by title only. Full-text search is M3 |
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
15. Until M3 the live index is `MemorySearchIndex`: an actor rebuilt by a full scan at each launch. The list, the badges and the editor lookup read it. M3 replaces it with `GRDBSearchIndex` behind the same port.
16. The panel and the window share one `EditorStore` until a second editor surface exists (more windows and floating notes, M7). Only one of the two is open at a time, because opening the window closes the panel.
17. A small conflict banner (Keep mine, Take theirs) came forward from M5, so a conflict never leaves typed text without a way to save it. M5 adds Open both, the journal and the S11 check.
18. `VaultChange` is `.paths(Set<VaultPath>)` or `.rescan`, without a kind: the reindex reads the disk for each path. `ARCHITECTURE.md` section 4.1 says so.
19. Stem rule, `STORAGE-FORMAT.md` 3.1 steps 3 and 4: tabs and line breaks count as whitespace (step 4 collapses them); step 3 removes the other control characters. No format change.
20. The New menu offers Note, Task, Snippet and Meeting. Daily comes with C10 (M4), because a daily note is named by its date and opened, not created twice.
21. M1 is one commit, not one per feature ID: C1, C2, C5, C7, C8, D6, D7, F1, F2 and B2 share the new ports, use cases and stores, and the steps between them would not build.
22. `STORAGE-FORMAT.md` section 1 said "default in iCloud Drive"; it now says `~/Documents/Slate` as ADR 0002 decided. This fixes the text, not the format.
23. Quit saves through `AppContainer`: a selector observer for `willTerminate` (main actor, no `assumeIsolated`) runs `EditorStore.pendingSave()` off the main actor and waits up to 3 s.

24. M1.5 editor spike: the own TextKit 2 core wins (open 71 ms, keystroke 2.2 ms on the 5,000-line fixture) over `MarkdownEngine` 0.9.0 (975 ms, 79 ms). No new dependency. ADR 0005 amendment has the numbers. The two spike branches `spike/own-core` and `spike/markdown-engine` stay local and are not merged; M2 takes the own-core files from `spike/own-core` as its start.
25. Branches during the long build: one branch per milestone, each made from the one before (`m1.5-editor-spike`, `m2-editor`, `m3-index-and-search`, …). Merging the last one brings all of them.

## Next steps

1. Owner: run the M1 manual checks (below). Merge the branch `m1-vault-and-notes` when they pass.
2. M2: editor v1 on the own core (decision 24).

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
- The in-memory index is rebuilt by a full scan at each launch. With thousands of notes the list fills a few seconds after launch until M3.
- Crash safety is the 500 ms autosave and the save on quit. The journal comes in M5.
- The list column uses `HSplitView` (240 to 400 pt); its width is not saved.
- `ActivityRecorder` and `ShellRunner` have no user yet (M5 git history).
- `.claude/skills/add-feature`, `add-use-case`, `build-and-run` and `update-docs` and the example in `.claude/rules/presentation.md` still show DevHub features.
- No `generate-vault.sh` yet (needed from M2).
- Previews in package files were not opened in Xcode yet.
