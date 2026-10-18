# Slate

Notes in folders, in the macOS menu bar. Working name; rename by replacing `Slate`, `slate` and `SLATE_` in this folder.

Slate is a small notes app. You keep notes in folders. You write in formatted text, with a format bar and shortcuts, and you put images in the text. Each note is a plain Markdown file in a folder you choose, so other apps (Obsidian, a text editor, scripts) can read and change it too.

Status: **phase 2 built; phase 3 (agents, tables with images in cells) built** on `main`. The owner's manual checks are open; the list is in `docs/STATUS.md`.

## Screenshots

The owner takes these on a real screen and puts them in `docs/screenshots/`.

| File | What it shows |
|---|---|
| `docs/screenshots/window.png` | The window: folders, note cards and a note with the format bar |
| `docs/screenshots/editor.png` | A note with a title, a checklist, a list, a quote, an image and a code block |
| `docs/screenshots/quick-note.png` | The quick note field over another app |
| `docs/screenshots/settings.png` | Settings → General |

## What it does

1. **Folders.** Make a folder with "+ New folder" or `⇧⌘N`. Double-click a folder to rename it. Right-click it to change the colour or the icon, to move it, or to delete it. When you delete a folder, its notes move to the quick note folder, and a toast offers Undo.
2. **Notes.** `⌘N` makes a note in the current folder. A note card shows the title, the date and two lines of text. Drag a card onto a folder to move the note. Pin, Move to, Duplicate and Move to Trash are in the "…" button and the right-click menu.
3. **Formatted text.** The format bar and the Format menu set the style: Title, Heading, Subheading, Body, Monospaced, bold, italic, strikethrough, checklist, bulleted and numbered lists, quote, link and image. You see the result, not Markdown marks.
4. **Tables.** The Table button or `⌥⌘T` adds a table. Click a cell to type; Tab, Enter and the arrow keys move between cells, and ⇧Enter starts a new line in the cell. The "+" strips on hover add a column or a row, and the right-click menu adds, aligns and deletes rows and columns. Drop or paste an image into a cell to show a thumbnail there. Select lines and press Table to turn them into a table. Shift-click or drag to select several cells, then copy, paste, clear or format them together. Wide tables scroll sideways, and Find in Note searches the cells. In the file a table is a GitHub table with `|`, so other apps can read it.
5. **Images in the text.** Paste an image, drag one in, use the Image button, or press `⇧⌘S` for a screenshot. Double-click an image to see it large. Drag the grip at its corner to change its size, and press the round button on it to save a copy to Downloads.
6. **Quick note.** `⌃⌥Space` opens a small field from any app. Enter saves the note, `⌘Enter` saves and opens it.
7. **Search.** `⌘F` searches the titles and the text of the current folder. "Search all notes" searches every folder.
8. **Light or dark.** Settings → General → Appearance, the right-click menu of the menu bar icon, or View → Appearance in the window: Match the system, Light or Dark.
9. **AI agents.** `slate mcp` lets Claude Code and other MCP clients list, search, read and change notes: run `claude mcp add -s user slate -- slate mcp` once. Settings → General → AI access says which folders agents may change. Copy Path, Copy Link and dragging a card hand one note to an agent. `CLAUDE.md` in the notes folder tells agents the rules. A **project** keeps the documentation of one code repository: an agent that works in the repository finds it with `project_context`, starts a task folder with `start_task`, adds files with `add_file` and writes a dated entry with `log_progress` at the end of each session. `slate project` and `slate task` do the same from the command line.
10. **Safe by default.** Slate saves as you type. It keeps versions of each note (the clock button next to the title) and can back them up to a git address. Deleted notes stay in the Trash for 30 days.

## Keys

| Keys | Action |
|---|---|
| `⌥⌘N` (from any app) | Open Slate |
| `⌃⌥Space` (from any app) | Quick note |
| `⌘N`, `⇧⌘N` | New note, new folder |
| `⌘F` | Search |
| `⌘0` | Show or hide the folders |
| `⇧⌘O` | Open the panel as a window |
| `⌘1` … `⌘9` | Folder by position |
| `⌘↑`, `⌘↓` | Previous and next note |
| `⇧⌘P` | Pin or unpin |
| `⌘⌫` | Move the note to the Trash (asks first) |
| `⇧⌘T`, `⇧⌘H`, `⇧⌘J`, `⇧⌘B`, `⇧⌘M` | Title, Heading, Subheading, Body, Monospaced |
| `⇧⌘L`, `⇧⌘7`, `⇧⌘9` | Checklist, bulleted list, numbered list |
| `⌘'` | Quote |
| `⌘B`, `⌘I`, `⇧⌘X` | Bold, italic, strikethrough |
| `⌘K` | Link |
| `⇧⌘I`, `⇧⌘S` | Image, screenshot |
| `⌥⌘T` | Table |
| `⌘,` | Settings |
| `Esc` | Back, and closes the panel |

## Build and run

```sh
Scripts/build.sh      # layer check, then xcodebuild; prints the .app path
Scripts/test.sh       # swift test on Packages/SlateKit
Scripts/run.sh        # build, quit the running app, open the new one
Scripts/install.sh    # Release build to /Applications and the slate CLI to ~/.local/bin
```

To keep `/Applications/Slate.app` at the last commit on `main`, add two git hooks once:

```sh
for h in post-commit post-merge; do printf '#!/bin/sh\nexec "$(git rev-parse --show-toplevel)/Scripts/auto-install.sh"\n' > .git/hooks/$h; chmod +x .git/hooks/$h; done
```

After a commit that changes code, Slate is built and installed in the background, and a notification says when it is done. The log is `.git/slate-install.log`.

## Claude Code

```sh
claude mcp add -s user slate -- slate mcp
ln -s "$PWD/Skills/slate-task" ~/.claude/skills/slate-task
```

The first line gives Claude Code the Slate tools in every folder. The second adds the `slate-task` skill: in a repository linked to a Slate project (Link Repository…), the agent finds its task at the start of a session, keeps Context, Plan, Findings and Log in the task note, and writes what is done and what is next at the end. The skill stays in this repository, so a change to it works in the next session. To use the tools without a question on each call, add `"mcp__slate"` to `permissions.allow` in `~/.claude/settings.json`.

You need Xcode with the macOS 26.4 SDK. You do not need a developer account: the app is signed to run on this Mac only. After `Scripts/run.sh` a note icon appears in the menu bar. Click it to open the panel. Click outside the panel to close it. To see the first launch window again, run `defaults delete local.slate.app vault.path`.

## Read in this order

| File | What it answers |
|---|---|
| `CLAUDE.md` | The rules for working in this repository |
| `docs/STATUS.md` | What is real, the decisions, the known gaps, the manual checks |
| `docs/ROADMAP.md` | Milestones with a "done when" check for each; phase 2 is S1 to S4 |
| `docs/SPEC.md` | What Slate is; section 0.9 is the v1 scope |
| `docs/UX.md` | The UI rule book (revision 2): layouts, components, words, keys |
| `docs/STORAGE-FORMAT.md` | The notes folder on disk: folders, Markdown with a header, links, images, Trash, config files; section 11 is the Markdown that the editor writes |
| `docs/ARCHITECTURE.md` | Modules and layers, ports, use cases, stores, the editor module |
| `docs/PLAYBOOK.md` | Solutions that work and traps, per topic |
| `docs/adr/` | Decisions and their reasons; 0007 is the v1 scope, 0008 the rich text editor |
