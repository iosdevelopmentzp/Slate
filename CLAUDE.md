# Slate

Personal macOS menu bar notes app for an iOS developer. Markdown files in a local notes folder, a SQLite search index, task notes with ticket and branch, quick capture from a hotkey.

Current stage: **M7 done** (polish); M0 to M7 are built, the owner's manual checks are open. Notes are real Markdown files in the notes folder chosen on first launch. The panel and the window list, create, edit, rename, pin, move, archive, duplicate, trash and restore notes; the editor autosaves; external edits reload. The editor styles Markdown with visible marks, highlights code, renders checkboxes and images, and handles paste and screenshots. The SQLite index lives in Application Support; search covers titles, text, tags and filters; links to notes complete, follow, create missing notes and follow renames. A global quick note field, Today with carried checkboxes, task notes with ticket, branch and status, link patterns from `.slate/links.json`, global hotkeys and a Settings window with a Doctor exist. Unsaved text is kept in a journal, conflicts offer Open both, git snapshots outside the notes folder give per-note versions with Restore and an optional push, and the Trash empties itself. The `slate://` URL scheme, the `slate` CLI, the Services menu entry, actions in `.slate/actions/`, saved searches, Open TODOs, the `⌘K` palette and export exist. Floating note windows, the main menu with the full keyboard map, editor habits (move and duplicate lines, comments, find), ticket details from the tracker and daily-note settings exist. Next: the owner's manual checks, then M8 ideas. `docs/STATUS.md` says what is real.

Read first, in this order: this file, `docs/STATUS.md`, `docs/ROADMAP.md`, then the document for the milestone (`docs/SPEC.md`, `docs/STORAGE-FORMAT.md`, `docs/ARCHITECTURE.md`, `docs/UX.md`). `docs/PLAYBOOK.md` has verified solutions and traps per topic; read its section before touching that topic.

## Project

- Xcode project `Slate.xcodeproj`, one app target `Slate`, macOS 26.4+, Swift 6 language mode, default actor isolation `MainActor`. The target holds only `Slate/SlateApp.swift` and `Assets.xcassets` and links the product `SlateComposition`. `SlateApp` hands the app delegate to `AppContainer` through `@NSApplicationDelegateAdaptor`.
- `Config/Slate-Info.plist` (`INFOPLIST_FILE`) holds the `slate://` URL scheme and the "Add to Slate" service; Xcode merges the generated keys into it (`GENERATE_INFOPLIST_FILE` stays on).
- Local package `Packages/SlateKit` (tools 6.2, Swift 6). `project.pbxproj` holds the package reference.
- No App Sandbox. Ad-hoc signing (`Sign to Run Locally`). No Apple Developer account. Keep it this way: the app shells out to `screencapture`, `git` and `open`.
- `INFOPLIST_KEY_LSUIElement = YES`: no Dock icon, the app lives in the menu bar only.
- `Slate/` is an Xcode synchronized folder. Edit `project.pbxproj` only for build settings, never for file lists. New code goes into the package, not into `Slate/`.

## Build & Run

| Command | What it does |
|---|---|
| `Scripts/build.sh [Debug\|Release]` | Runs `Scripts/check-layers.sh`, then builds with `xcodebuild -quiet` into `DerivedData/` and prints the `.app` path. `SKIP_LAYER_CHECK=1` skips the check |
| `Scripts/test.sh [args]` | Runs `swift test -q` on the package and prints one summary line. `--skip integration` skips the process suites, `--filter <Suite>` runs one suite |
| `Scripts/run.sh` | Builds Debug, quits a running Slate, opens the new build |
| `Scripts/install.sh` | Builds Release, copies to `/Applications/Slate.app`, installs the `slate` CLI to `~/.local/bin` |
| `Scripts/generate-vault.sh <folder> <count>` | Writes sample notes for performance checks. `SLATE_PERF_VAULT=<folder> swift test --filter IndexPerformanceTests` times a full scan and a search over it |

Run `Scripts/build.sh` and `Scripts/test.sh` after every change. `build.sh` prints `layers: ok` and the app path; anything else is a layer violation, an error or a warning. `test.sh` prints one `Test run with … passed` line. A failing test, or a missing test for new logic, counts as a failure.

## Layout

Modules, one direction: `Composition → Presentation → Domain ← Data`; Presentation also uses UI and Editor; the CLI uses Domain and Data. The compiler enforces the direction. Full contract in `docs/ARCHITECTURE.md`, short rules in `.claude/rules/`, extra checks in `Scripts/check-layers.sh`.

| Path | Purpose |
|---|---|
| `Slate/` | App host: `SlateApp.swift` (`@main`, `@NSApplicationDelegateAdaptor(AppContainer.self)`) and `Assets.xcassets`. Nothing else |
| `Config/` | `Slate-Info.plist`: URL scheme and Services, merged with the generated Info.plist |
| `Packages/SlateKit/Sources/SlateDomain/` | models, values, ports, policies, codec, use cases, `Ports`, `UseCases` |
| `…/SlateData/` | live ports: `Files/`, `Index/` (GRDB and FTS5), `Watch/`, `Shell/`, `History/`, `Capture/`, `Secrets/`, `Persistence/`, `System/` (AppKit only here), `Assembly/Ports+Live.swift` |
| `…/SlateMocks/` | mocks and `Ports.mock()` |
| `…/SlateUI/` | shared SwiftUI blocks, `Theme`, `Tint`, formatters, hints |
| `…/SlateEditor/` | the TextKit 2 Markdown editor; imports nothing from the package |
| `…/SlatePresentation/` | `Shared/`, `Shell/` (`AppWindows`, `RootView`), `Features/<Name>/` |
| `…/SlateComposition/` | `AppContainer` (the app delegate, the only `public` type), `ServicesProvider` |
| `…/SlateTestSupport/` | spies and test helpers |
| `…/SlateCLI/` | the `slate` command |
| `Packages/SlateKit/Tests/` | six test targets (`SlateCLITests` runs the commands over a temporary folder), folders mirror `Sources/` |
| `Scripts/` | `build.sh`, `test.sh`, `check-layers.sh`, `layer-exceptions.txt`, `run.sh`, `install.sh`, `generate-vault.sh` |
| `docs/` | `SPEC.md`, `STORAGE-FORMAT.md`, `ARCHITECTURE.md`, `UX.md`, `ROADMAP.md`, `PLAYBOOK.md`, `BOOTSTRAP.md`, `STATUS.md`, `adr/` |
| `.claude/rules/` | `layers.md` (always), `domain.md`, `data.md`, `presentation.md`, `testing.md` (by path) |
| `.claude/skills/` | `add-feature`, `add-use-case`, `build-and-run`, `panel-window`, `testing`, `ui-components`, `update-docs` (copied from DevHub; examples still name DevHub features) |
| `.claude/hooks/` | session brief on start, changelog check on stop |

## Rules that apply from day one

- The storage format in `docs/STORAGE-FORMAT.md` is a contract shared with other tools (Obsidian, the CLI, scripts). Change it only with a new ADR in `docs/adr/`.
- Every screen follows `docs/UX.md` revision 2: native but soft, rounded, two visible concepts (Folders, Notes), keyboard first, no modal dialogs, plain words from its section 7.
- v1 scope is `SPEC.md` section 0.9 (ADR 0007). A parked feature never appears in the UI. The editor is rich text with Markdown files (ADR 0008); no Markdown marks on screen.
- No comments in code (`check-layers.sh` fails on a comment line; `// MARK` is allowed). Names and small functions carry the meaning.
- Swift conventions as DevHub: `package` across modules, `guard` for early exit, `== false` instead of `!`, `[weak self]` closures start with `guard let self else { return }`, one type per file, block indentation for multi-line calls.
- Plain English in documentation, UI text, commit messages and the changelog: short sentences, common words, no idioms.
- Every change to code updates `CHANGELOG.md` under `[Unreleased]` and, when the stage moves, `docs/STATUS.md`. The Stop hook blocks a session that changed `Slate/`, `Packages/`, `Scripts/` or `.claude/` without touching the changelog.

## The app is anonymous

No company, product, host, ticket prefix, branch pattern or person name appears in Swift, resources, defaults, tests, fixtures, docs or commit messages (ADR 0006). Examples use `ABC-123`, `example.atlassian.net`, `gitlab.example.com`. Project facts come only from Settings and `.slate/` files in the user's notes folder. Xcode's generated file headers carry the owner's name: remove them.

## Working rules for the build agent

- One feature ID at a time (`docs/SPEC.md` section 4). Finish it end to end: Domain, Data, Presentation, tests, a manual check, `CHANGELOG.md`. Then commit.
- Read `docs/PLAYBOOK.md` before touching a topic it covers. Do not rediscover those problems.
- Run `Scripts/build.sh` and `Scripts/test.sh` after every change. Both clean before a commit.
- A step that fails twice in a row: stop, write what failed and what was tried into `docs/STATUS.md` under "Known gaps", and continue with the next item. Do not loop.
- Never widen the task: no refactor of untouched code, no new abstraction without a second user, no new package without an ADR.
- When a doc and the code disagree, fix one of them in the same session and say which.
- The skills under `.claude/skills/` were copied from DevHub. Treat their examples as patterns, take the Slate types from `docs/ARCHITECTURE.md`, and update a skill the first time its topic is touched.
