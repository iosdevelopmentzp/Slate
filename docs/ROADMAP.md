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
| M8 | **Ideas** | A8, B8, B9, C12, D10, D11, E5, F3, F7, G6, G7, G8 | Each one lands as its own decision in `docs/STATUS.md` |

## Rules for the agent during the build

- Every view is checked against `docs/UX.md` before its milestone is called done.

- Build in the order above. A later milestone may start only when the earlier one's "done when" holds.
- Before M1: read `STORAGE-FORMAT.md` in full. Before M2: read `PLAYBOOK.md` section 9. Before M3: `PLAYBOOK.md` section 10. Before M4: sections 1, 2, 3, 8. Before M5: sections 4, 5, 8. Section 6 only with F3.
- A fixture vault lives in `SlateTestSupport/VaultFixture` and is written to a temporary folder by tests; the 5,000-line editor fixture is a resource of `SlateEditorTests`.
- Every milestone updates `CLAUDE.md` when a new script, skill or rule appears.
- Decisions that must not be undone go to `docs/STATUS.md` under "Decisions" with the ADR number when there is one.
