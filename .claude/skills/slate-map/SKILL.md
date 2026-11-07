---
name: slate-map
description: "Map of the Slate repository: which document to read and which folder to open for a topic before you change it. Covers the docs, the modules, the editor (TextKit 2, Markdown reader and writer, tables, links, paste), the stores and views, the notes folder format, versions and history, search, the slate CLI and slate mcp, scripts, tests and the other skills. Load it at the start of any task in this repository, when you do not know where something lives, or before you add a new feature."
---

# Slate map

This skill says where to look. It does not repeat the rules: the documents and the code are the source. When this map and the code disagree, trust the code and fix the map in the same session.

## 1. Read first

| Question | Read |
|---|---|
| What is real now, what is open, the numbered decisions | `docs/STATUS.md` (Stage, Decisions, Known gaps, Manual checks) |
| What the app should do, feature IDs | `docs/SPEC.md` (section 0.9 is the v1 scope) |
| Order of the work, parked ideas | `docs/ROADMAP.md` (M8 and "Future ideas") |
| Modules, types, data flows | `docs/ARCHITECTURE.md` (section 2 is the folder map, section 6 the editor) |
| File format of the notes folder | `docs/STORAGE-FORMAT.md` (section 11 is the editor's Markdown subset) |
| Look, words on screen, keys | `docs/UX.md` (section 4 components, 7 words, 8 keyboard) |
| Problems already solved | `docs/PLAYBOOK.md`, one section per topic |
| Why something is the way it is | `docs/adr/` (one file per decision) |
| What changed recently | `CHANGELOG.md` under `[Unreleased]`, then `git log --oneline -20` |
| Rules for code | `CLAUDE.md`, then `.claude/rules/` (`layers.md`, `domain.md`, `data.md`, `presentation.md`, `testing.md`) |

## 2. Where the code is

All code is in `Packages/SlateKit/Sources/`. Tests mirror it in `Packages/SlateKit/Tests/<Module>Tests/`.

| Topic | Folder |
|---|---|
| Models, ports, use cases, policies | `SlateDomain/` (`Models/`, `Ports/`, `UseCases/`, `Policies/`, `Codec/`) |
| Files on disk, index, watcher, git history | `SlateData/` (`Files/`, `Index/`, `Watch/`, `History/`, `Git/`, `Assembly/Ports+Live.swift`) |
| Editor: text view, commands, hover cards, menus | `SlateEditor/Core/` (`RichTextController+<Concern>.swift`) |
| Markdown to rich text and back | `SlateEditor/Markdown/` (`MarkdownReader`, `MarkdownWriter`, `InlineReader`, `InlineWriter`) |
| Copy for Jira and Slack (Markdown to wiki markup and Slack text) | `SlateEditor/Markdown/Export/` |
| Look of blocks (quote bar, code, lists) | `SlateEditor/Styling/` (`RichTextStyler`, `RichLayoutFragment`) |
| Attributes of the rich text | `SlateEditor/Model/` (`RichText`, `BlockKind`, `InlineStyle`) |
| Paste, copy, the pasteboard | `SlateEditor/Paste/` (the only editor folder that may use `NSPasteboard`) |
| Tables | `SlateEditor/Tables/` |
| Code colours | `SlateEditor/Highlighting/` |
| Note screen, format bar, banners | `SlatePresentation/Features/Editor/` |
| Notes list, Back and Forward | `SlatePresentation/Features/NoteList/`, `Shared/Navigator.swift`, `Shared/NavigationHistory.swift` |
| Folders, sidebar, menus, window | `SlatePresentation/Features/Vault/`, `Shell/` (`SidebarView`, `MainMenuBuilder`, `AppWindows`) |
| Versions and folder changes | `SlatePresentation/Features/History/`, `SlateData/History/` |
| Search | `SlatePresentation/Features/Search/`, `SlateData/Index/` |
| App updates (check, Update Now, progress) | `SlatePresentation/Features/Update/`, `SlateData/Update/`, `Scripts/update.sh`, ADR 0023 |
| Settings | `SlatePresentation/Features/Settings/` |
| Shared SwiftUI blocks, colours | `SlateUI/` |
| Building the object graph | `SlatePresentation/Shared/PresentationAssembly.swift`, `SlateComposition/` |
| `slate` CLI and `slate mcp` tools | `SlateCLI/` (`MCPToolCatalog` lists tools, `MCPToolRunner+<Area>` runs them) |
| The guide agents read in the notes folder | `SlateDomain` `AgentGuide` (written into the notes folder `CLAUDE.md`) |
| Spies and test helpers | `SlateTestSupport/` |

To find a symbol, use the tokensave tools when the project has an index, or `grep -rn` over `Packages/SlateKit/Sources`.

## 3. Which skill next

| Task | Skill |
|---|---|
| Build, test, install, fix a build error | `build-and-run` |
| Write or fix a test | `testing` |
| A new screen or feature end to end | `add-feature` |
| Logic that belongs in Domain, two stores that must talk | `add-use-case` |
| A SwiftUI view, shared components | `ui-components` |
| Window, menu bar item, hot keys | `panel-window` |
| End of a session: changelog, status, docs | `update-docs` |
| Task documentation in Slate from another repository | `Skills/slate-task/` |

The skills `add-feature` to `ui-components` were copied from DevHub. Read their examples as patterns.

## 4. Checks before a commit

- `Scripts/build.sh` prints `layers: ok`, `deps: ok` and the app path.
- `Scripts/test.sh` prints one passing line (`--skip integration` for a quick run, `--filter <Suite>` for one suite).
- `CHANGELOG.md` has a line under `[Unreleased]`. `docs/STATUS.md` has a decision when a choice was made, and a manual check when the change needs a person to look at it.
- A new agent-visible feature: a tool in `MCPToolCatalog` when agents need it, and a line in `AgentGuide`.

## 5. Keep this map current

Update this file in the same commit when you add a module folder, a document, a skill, or move a topic to a new place. `update-docs` checks it at the end of a session.
