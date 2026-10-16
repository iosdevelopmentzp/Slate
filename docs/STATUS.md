# Status

Last updated: 2026-10-16

## Stage

M0 done (skeleton), manual checks by the owner still open. The menu bar icon opens the panel: a header with the folder menu and title search, the note list, the selected note with a plain editor, and a footer. "Open as window" opens a normal window with a sidebar of folders. The notes come from `MockVault` (six notes in Inbox and Tasks); nothing is read from or written to disk. 48 tests in 19 suites pass. Next: milestone M1 of `docs/ROADMAP.md`.

## Screens

| Screen | State | Notes |
|---|---|---|
| Panel | mock | `MenuBarPanel`, `WindowLayout`, drag and resize from DevHub. Header: folder menu, title search (`⌘F`), Open as window. No New button and no Settings button yet: both arrive with M1 and M7 |
| Window | mock | Same root view with a sidebar (Folders with counts, `⌘0` hides it). No Tags, Saved searches or Trash in the sidebar yet |
| Capture field | planned | |
| Note list | mock | Rows from `NoteRowMapper`: title, relative date, two-line preview, status dot, ticket, attachment and checkbox badges, pin. No hover actions yet (Pin, More) |
| Editor | placeholder | `NoteDetailView` shows the title, chips and `MarkdownEditorView` filled with the note preview; edits are not saved. M1 brings `EditorStore` |
| Search | partial | Filters the loaded list by title only. Full-text search is M3 |
| Settings | planned | |

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

## Next steps

1. Owner: run the M0 manual checks (below) and commit. The repository has no commit yet.
2. M1: vault and notes. Read `STORAGE-FORMAT.md` in full first.

M0 manual checks for the owner: `Scripts/run.sh`; click the menu bar icon; the panel shows six notes, the folder menu switches between All notes, Inbox and Tasks; a click outside closes the panel; drag the header to move it, drag the grip to resize it, double-click the header to put it back under the icon; Open as window shows the sidebar and `⌘0` hides it; switch the system to dark mode and check both surfaces.

## Known gaps

- The seven skills under `.claude/skills/` were copied from DevHub with a rename. Their examples still name DevHub features. Each one needs a pass against `docs/ARCHITECTURE.md` when its topic is first touched.
- `.claude/rules/presentation.md` and `testing.md` still show DevHub examples (worktrees, simulators). Same treatment.
- No `generate-vault.sh` yet (needed from M2).
- Previews in package files were not opened in Xcode yet.
- M0 visual check was not done by the agent: no Screen Recording permission, and the borderless panel hides its content from the Accessibility API. Checked: the app starts, and a click on the icon puts a 883 × 613 panel on screen (clamped to this screen, layer 25).
- Esc does not close the panel yet (`UX.md` section 6). The search field clears on Esc.
- The list column uses `HSplitView` (240 to 400 pt); its width is not saved.
- `RowContainer` and other copied blocks pad 14 pt; `UX.md` asks for 12. Change them when a screen first uses them.
- `.claude/skills/add-feature`, `add-use-case`, `testing`, `build-and-run` and `update-docs` still show DevHub examples.
