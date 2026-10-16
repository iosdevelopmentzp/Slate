# Slate

Notes for an iOS developer on macOS. Working name; rename by replacing `Slate`, `slate` and `SLATE_` in this folder.

Apple Notes is fast and simple. It misses what a developer needs every day: Markdown and code blocks, a note tied to a ticket and a branch, a screenshot in one keystroke, search that finds a line inside a code block, plain files you own, and a way to add features without writing a new app. Slate keeps the speed of Notes and adds those things.

Status: **milestone M0**. The menu bar icon opens a panel with sample notes in two folders; "Open as window" opens a window with a sidebar. The notes are sample data and nothing is saved yet. The documents in `docs/` describe what to build, how the data is stored, how the code is organised and in which order to build it. Next: milestone M1 of `docs/ROADMAP.md`.

## Run

```sh
Scripts/build.sh      # layer check, then xcodebuild; prints the .app path
Scripts/test.sh       # swift test on Packages/SlateKit
Scripts/run.sh        # build, quit the running app, open the new one
Scripts/install.sh    # Release build to /Applications and the slate CLI to ~/.local/bin
```

Needs Xcode with the macOS 26.4 SDK. No developer account: the app is signed to run locally. After `Scripts/run.sh` a note icon appears in the menu bar. Click it to open the panel. Click outside the panel to close it. `⌘F` searches note titles, `⌘Q` quits. In the window, `⌘0` shows or hides the sidebar.

## Read in this order

| File | What it answers |
|---|---|
| `docs/SPEC.md` | What Slate is, principles, daily scenarios, every feature with a priority, the shell and the editor, search, sync, integrations, settings, keyboard map, budgets, risks, open questions |
| `docs/STORAGE-FORMAT.md` | The vault on disk: folders, Markdown with a YAML header, links, attachments, trash, templates, config files, the search index |
| `docs/ARCHITECTURE.md` | Modules and layers, ports, use cases, stores, the editor module, concurrency, tests, scripts, dependencies, extension points |
| `docs/UX.md` | The UI rule book: native look, three visible concepts, layouts, components, states, UI words, keyboard |
| `docs/PLAYBOOK.md` | Verified solutions and traps per topic; read the section before writing code for it |
| `docs/ROADMAP.md` | Milestones with a "done when" check for each |
| `docs/BOOTSTRAP.md` | How to start the repository: Xcode settings, what to copy from DevHub and Verba, external packages, the first prompt for the agent |
| `docs/adr/` | Decisions and their reasons |

## Summary in one paragraph

A menu bar app. One global hotkey opens a panel with a note list and an editor. A second hotkey opens a small capture field. Notes are Markdown files with a YAML header, in a local folder you choose. A git repository stored outside the folder keeps the history and pushes to a private remote when you set one. A SQLite full-text index makes search instant and can be rebuilt from the files at any time. A task note carries a ticket, a branch and a merge request. A CLI and a URL scheme let scripts, DevHub and Claude Code create and append notes.
