# Roadmap

Milestones for the build. Each one ends with: `Scripts/build.sh` clean (`layers: ok`, the app path, nothing else; anonymity is checked by reading the diff, ADR 0006), `Scripts/test.sh` one passing line, the manual checks below done by hand, `CHANGELOG.md` and `docs/STATUS.md` updated, a commit. Inside a milestone every finished feature ID is also a commit.

The remote, when there is one, always holds a working app. A half-done feature is not reachable from the UI.

Feature IDs refer to `SPEC.md` section 4. P0 is M0 to M5. If time runs out, M0 to M4 are mandatory.

| # | Milestone | Scope (feature IDs) | Done when |
|---|---|---|---|
| — | **Bootstrap** (done 2026-10-16) | Xcode project, package with nine modules, scripts, hooks, rules, skills, docs | `Scripts/build.sh` and `Scripts/test.sh` are clean; a menu bar icon opens a placeholder panel |
| M0 | **Skeleton** (done 2026-10-16, manual checks open) | package with all modules and empty tests, `Scripts/`, hooks, `Theme`, `SlateUI` blocks copied from DevHub and renamed, status item, panel, window, `WindowLayout`, `Navigator`, `AppEvents`, `ActivityLog`, `Toaster`, mock vault, `RootView` with a mock list and a plain `TextEditor`, previews, `README.md` | The panel opens from the menu bar with mock notes in two spaces; the window opens with the sidebar; `build.sh` and `test.sh` are clean with at least one test per test target |
| M1 | **Vault and notes** (done 2026-10-16, manual checks open) | C1, C2 (built-in types and templates), C5 (pin, archive, trash without purge), C7, C8, D6 (autosave, no journal yet), D7, F1, F2 (watcher and reload when not dirty; the banner comes in M5), B2 | A note typed in the panel is a `.md` file with a header in Finder within one second; a file created in Finder shows in the list; renaming in the title field renames the file; `FrontmatterParserTests`, `StemPolicyTests`, `FileVaultStoreTests`, `NoteListStore` and `EditorStore` tests pass |
| M1.5 | **Editor spike** (done 2026-10-16: own core, ADR 0005 amendment) | — | Two throwaway branches: (a) own `FenceTracker` plus paragraph delegate styling, (b) the open-source `MarkdownEngine` package. Each renders the 5,000-line fixture with headings, lists, fences and images. Measure keystroke latency and start time. Write the decision and the numbers into `docs/STATUS.md` and ADR 0005 (amend). Default when equal: own code, no new dependency |
| M2 | **Editor v1** (done 2026-10-16, manual checks open) | D1, D2, D3, D4, D5 (URLs and wikilink styling; patterns in M4), B4, B5 | Scenario S2 and S3 pass; typing in the 5,000-line fixture shows no dropped frames; clicking a checkbox writes `x` into the file; `FenceTrackerTests`, `CodeHighlighterTests`, `ListEditingTests`, `PasteClassifierTests` pass |
| M3 | **Index and search** (done 2026-10-16, manual checks open) | E1, E2, C4, C6 (autocomplete, follow, create missing, rewrite on rename), index-backed list (C7 badges from the index) | `Scripts/generate-vault.sh` with 10,000 notes: full scan under 20 s, a two-word search under 50 ms; S6 passes; rename a note linked from three notes and all three update; `GRDBSearchIndexTests`, `FTSMatchBuilderTests`, `WikilinkPolicyTests`, `SearchQueryParserTests` pass |
| M4 | **Capture and tasks** (done 2026-10-16, manual checks open) | B1, B3, A4, A5, C3, C10, C11, G1, H1, H2, H6, D5 (patterns) | S1, S4 (Today part), S5, S7 pass; the capture field never activates the app; link patterns edited in `links.json` apply without a restart; `TitlePolicyTests`, `SlugPolicyTests`, `DailyPolicyTests`, `TemplateRendererTests`, `LinkPatternPolicyTests`, `CaptureStore` tests pass |
| M5 | **Safety and history** (done 2026-10-16, manual checks open) | F2 (conflict banner), F4 (purge), D6 (journal), F5, H4 | S11 and S12 pass; kill the app while typing and the text survives; a snapshot appears after an edit and a push reaches a test remote; no `.git` in the vault; `ConflictPolicyTests`, `FileTrashRepositoryTests`, `GitHistoryRepositoryIntegrationTests` pass |
| M6 | **Extension points** (done 2026-10-16, manual checks open) | G2, G3, G4, B6, C9, E3, E4, A7, F6 | S10 passes; `open "slate://new?title=Hi"` creates and shows a note; Services → Add to Slate works from Safari; Open TODOs toggles an item in its file; `URLCommandParserTests`, CLI tests over a temporary vault pass |
| M7 | **Polish** (done 2026-10-16, manual checks open) | A6, D8, D9, G5, H3, H5, Doctor details, dark mode pass, keyboard pass (every item of the keyboard map) | Every row of `SPEC.md` section 10 works; a floating note stays above Xcode; Jira details show when a token is set and the key only when offline |
| M8 | **Ideas** (parked by ADR 0007) | A8, B8, B9, C12, D10, D11, E5, F3, F7, G6, G7, G8 | Each one lands as its own decision in `docs/STATUS.md` |

## Rules for the agent during the build

- Every view is checked against `docs/UX.md` before its milestone is called done.

- Build in the order above. A later milestone may start only when the earlier one's "done when" holds.
- Before M1: read `STORAGE-FORMAT.md` in full. Before M2: read `PLAYBOOK.md` section 9. Before M3: `PLAYBOOK.md` section 10. Before M4: sections 1, 2, 3, 8. Before M5: sections 4, 5, 8. Section 6 only with F3.
- A fixture vault lives in `SlateTestSupport/VaultFixture` and is written to a temporary folder by tests; the 5,000-line editor fixture is a resource of `SlateEditorTests`.
- Every milestone updates `CLAUDE.md` when a new script, skill or rule appears.
- Decisions that must not be undone go to `docs/STATUS.md` under "Decisions" with the ADR number when there is one.

## Phase 2: the simple v1 (ADR 0007, ADR 0008, `UX.md` revision 2)

Starts from the merged M0 to M7 code. Same rules: build and tests clean, changelog, status, a commit per finished feature, never a broken repository. Read `SPEC.md` section 0.9, ADR 0007, ADR 0008 and `UX.md` in full before S1.

| # | Milestone | Scope | Done when |
|---|---|---|---|
| S1 | **Simplify** (built 2026-10-17, manual checks open) | Remove every parked feature from every surface (ADR 0007): menus, status item menu, capture field, sidebar, list rows, editor header, palette, Settings pages, first-launch bootstrap (one folder `Notes`, no templates, types, views, links, actions). Delete the Presentation code that served only parked features; keep Domain and Data and their tests. Hotkeys: Open Slate, Quick note, New note only | The app shows Folders, Notes, search, Trash, Settings with two pages; `git grep` finds no parked word in `SlatePresentation` (`ticket`, `task`, `daily`, `snippet`, `meeting`, `tag`, `template`, `action`, `palette`, `todo`); build and tests clean; `STATUS.md` lists what was removed and the commit that still has it |
| S2 | **Folders and the soft look** (built 2026-10-17, manual checks open) | Folders in panel and window: create (`⇧⌘N`), inline rename, delete with inline confirm and notes moved to the default folder, reorder, colour and icon in `spaces.json`; three columns in both surfaces; cards, pills, rounded corners, spacing and empty states per `UX.md` sections 2 to 5; drag a card onto a folder | Every item of `UX.md` section 9 holds for the sidebar, the list and the empty states; a folder made in the app appears in Finder; a folder made in Finder appears in the sidebar; light and dark previews |
| S3 | **Rich text editor** (built 2026-10-17, manual checks open) | `MarkdownReader.read` and `MarkdownWriter.write` with the subset of `STORAGE-FORMAT.md` section 11 and raw blocks; the format bar; every command and shortcut of `UX.md` section 8; list behaviour; images as blocks by paste, drag, the Image button and `⌘⇧S`; Quick Look; undo for every command; "Saved" indicator; the round-trip tests over a fixture set that includes files from Obsidian | Open a note, press `⇧⌘T`, type, press `⌘B`, add a checklist and an image, close: the file holds exactly the subset Markdown; reopen: it looks the same; a file with a table keeps its table after a save; typing on the 5,000-line fixture has no visible delay |
| S4 | **Polish and the owner's pass** (built 2026-10-17, manual checks open) | The quick note field with the folder menu; Settings per `UX.md` section 2; Check-up; toasts with Undo for Trash and Move; keyboard pass over `UX.md` section 8; `README.md` with screenshots the owner takes; the manual checks of S1 to S3 written as a list in `STATUS.md` | The owner runs the list and every item passes or is a numbered gap in `STATUS.md` |

## Phase 3: agents and tables (ADR 0010, ADR 0009)

Starts from `main` after S4 and the sub-folders work (ADR 0011). Same rules as Phase 2. S5 comes first: it is cheaper and it serves the owner's daily work; S6 is the larger UI risk.

| # | Milestone | Scope | Done when |
|---|---|---|---|
| S5 | **Agents and the notes folder** (ADR 0010, section "Milestone S5"; done 2026-10-17, manual checks open) | The `CLAUDE.md` / `AGENTS.md` block with markers; Copy path, Copy link, `⌥`-click, card drag-out; `slate mcp` with the eleven tools and the note resource; `.slate/agents.json`; the AI access box in Settings; a snapshot and an Activity line per agent write; the registration line in `Scripts/install.sh`; the welcome note line | The "Done when" paragraph of ADR 0010; `AgentGuideWriterTests`, `AgentPermissionsTests`, `MCPToolTests`, `NoteDragTests` pass |
| S6 | **Tables, level 1** (ADR 0009, section "Milestone S6"; done 2026-10-17, manual checks open) | `TableModel`, the table block attachment and view, the Table button and `⌥⌘T`, cell editing with inline styles, keyboard rules, hover handles, context menu, column widths, copy and paste, undo, reader and writer with `\|`, raw fallback, `STORAGE-FORMAT.md` section 11 row, `UX.md` component row | The "Done when" paragraph of ADR 0009; `TableMarkdownTests`, `TableModelTests`, `TablePasteTests` pass |
| S7 | **Tables, level 2: images in cells** (done 2026-10-17 before the owner's check of S6, see `STATUS.md` decision 125) | Only after the owner accepts S6 | Thumbnails in cells by drop, paste and the Image button; Quick Look; the file keeps `![](…)` inside the cell |
