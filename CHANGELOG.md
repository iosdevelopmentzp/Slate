# Changelog

All notable changes to Slate. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Newest first.

Every session that changes code adds lines under **Unreleased** before it ends. One line per user-visible change, described as behaviour, not as files. Scripts, hooks, skills and docs go under **Infrastructure**.

## [Unreleased]

### Added
- Versions: Slate saves a version of the notes folder every 10 minutes when something changed, at launch and on quit, with git in its own folder outside the notes folder. The clock button next to the title lists the versions of a note; Restore brings one back and keeps the current text as a version too. With a remote set in Settings → History every version is also pushed.
- Unsaved text survives a crash: Slate keeps a copy every second and offers it with Restore and Discard when the note opens again.
- "Changed on disk" also offers Open both: your text becomes a new note named "(conflict date time)" next to the version on disk.
- The Trash empties itself after the days set in Settings; Delete now removes one note at once. Both move the file to the macOS Trash.
- The footer shows the time of the last version and the push state, and an Activity button lists recent problems.
- Quick note: `⌃⌥Space` in any app opens a small field. Enter saves the note in Inbox and the app you were in keeps the focus. `⌘Enter` saves and opens the note, `⌥Enter` adds a timed line to Today, Esc closes and keeps the text for next time. A text that starts with a ticket key becomes a task.
- Today: `⌥⌘T` opens today's note, made from the daily template. Open checkboxes from the last daily note come along under "Carried over". `⌘[` and `⌘]` go to the day before and after.
- Tasks: a new task takes the ticket from its title, gets a suggested branch and the status To do. The ticket chip opens the tracker, the branch chip copies the branch, the status chip changes the status, `⌘⇧D` marks the task done. The Tasks folder groups its list into Active, To do and Done.
- Ticket keys, merge requests (`!1234`) and issues (`#12`) in the text are links once the addresses are set in Settings → Links. Changes to `.slate/links.json` apply at once. A pasted tracker or merge request URL becomes its short form; `⌘Z` brings the full URL back.
- Insert Template in the New menu puts a template into the open note.
- Settings (`⌘,`, the gear button or the menu bar menu): open at login, the folder for quick notes, text size, appearance, days in the Trash, the notes folder, the three global shortcuts, the tracker and git host addresses, and a Doctor with Rebuild search.
- Right click on the menu bar icon: New Note, New Task, Quick Note, Today, Open Window, Settings, Quit. `⌥⌘N` shows or hides Slate from any app.
- Search finds words in titles, text, tags and tickets across thousands of notes in a few milliseconds. Filters work in the same field: `tag:`, `space:`, `type:`, `ticket:`, `status:`, `is:todo`, `is:pinned`, `has:image`, `has:code`, `has:link`, `before:`, `after:`, and `-` to leave out a word or a filter. Results show the matching text with the words in bold; Enter opens the first one with the cursor on the match.
- Search stays in the folder you are in; "Search all notes" widens it.
- Tags: `#tag` in the text and `tags:` in the details count as tags. The window sidebar lists them with counts; a click shows the notes with that tag. Tag chips under the title do the same. Typing `#` and a letter offers the tags you have.
- Links to notes: typing `[[` offers note names; a `⌘`-click on a link to a missing note makes that note. Renaming a note updates the links to it in other notes.
- The editor styles Markdown while you type and keeps the marks visible: headings are larger, bold and italic show, inline code is monospace, links and links to notes are coloured, quotes get a bar, lists get a hanging indent, rules draw a line. A 5,000-line note opens in a fraction of a second and typing stays instant.
- Code blocks have a tinted background, monospace text and colours for Swift, Objective-C, JSON, YAML, shell, diff and logs. A Copy button appears on hover. Tab inside a code block inserts four spaces.
- Checkboxes `- [ ]` show as boxes. Click a box to check it; the file gets an `x`. `⌘⇧L` turns the line into a box, checks it, then makes it a plain item.
- Enter continues a list or a quote with the same marker; Enter on an empty item ends the list. Numbered lists count on. Tab and `⇧Tab` indent and outdent list items.
- `⌘B`, `⌘I` and `` ⌘` `` wrap the selection in `**`, `*` or a backtick, or remove them again. `⌘⇧K` inserts a link with the URL from the clipboard.
- `⌘`-click or `⌘Enter` opens a link. A link to another note (`[[Name]]`) opens that note.
- Images in `_attachments/` show under their line, as wide as the editor and at most 360 points high. Double-click opens Quick Look; right click offers Open, Quick Look, Show in Finder, Copy Image and Remove Image.
- Paste an image and it is saved in `_attachments/` and shown in the note. Paste files and they are copied there with a link each; files over 50 MB are linked where they are.
- Paste text that looks like code or a log and a bar asks "Paste it as a code block?"; Enter accepts, Esc keeps the text. `⌘⇧V` always pastes as a code block. Rich text keeps bold, italic and links as Markdown.
- `⌘⇧S` takes a screenshot of a region and `⌘⇧W` of a window. The panel hides during the capture, and the image lands in the note at the cursor.
- On first launch Slate asks where to keep the notes (default `~/Documents/Slate`) and prepares the folder with six folders, templates, settings files and a welcome note.
- Notes are Markdown files with a header. The list shows the notes on disk and follows changes made in Finder or another editor.
- `⌘N` makes a note in the current folder and puts the cursor in the title; `⌘⇧T` makes a task in Tasks from the task template. The New menu also offers Snippet and Meeting.
- The editor saves half a second after you stop typing, when you switch notes, when the panel or the window closes, and on quit.
- Changing the title renames the file. A new untitled note takes its title from its first line until you type a title.
- A note that changes on disk reloads when you have not edited it. When you have, a banner offers Keep mine or Take theirs; nothing is overwritten without asking.
- Pin, Move to, Duplicate, Archive and Move to Trash on each row (hover or right click). Moving to the Trash asks first and the toast offers Undo. The Trash lists the notes with their folder and restores them.
- Sort the list by date changed, date created or title (folder menu). Pinned notes stay on top.
- In the window sidebar: New folder, and Rename, Icon, Move up, Move down for each folder. A folder made in Finder appears as a folder in Slate.
- The menu bar icon opens a panel with the note list and the editor. The panel can be moved and resized and remembers both.
- The folder menu in the header switches between All notes, one folder and the Trash. The search field (`⌘F`) filters the list by title.
- List rows show the title, the date, a two-line preview, the status, the ticket, the number of images and open checkboxes, and a pin for pinned notes.
- The selected note shows its title and chips above a plain editor.
- "Open as window" opens a normal window with a sidebar of folders and their note counts. `⌘0` hides the sidebar.
- The app follows the system appearance, light or dark.

### Changed

### Fixed

### Infrastructure
- M5: history and journal ports with `GitHistoryRepository` (real git integration tests, push to a bare remote) and `FileJournalStore`; trash retention, journal and conflict copy policies; snapshot, restore and purge use cases; `HistoryStore`; tolerated exit codes in `ShellRunner`.
- M4: title, slug, daily, section append, link pattern and task group policies; create, daily, append and quick capture use cases; ports for the login item and the Doctor checks with live, mock and spy versions; `CaptureStore`, `DailyStore`, `SettingsStore`.
- M3: SQLite index with full-text search (GRDB, FTS5) in Application Support, rebuilt when it belongs to another folder or schema. `Scripts/generate-vault.sh` writes sample notes; with 10,000 of them a full scan takes 11 s and a search 28 ms in a debug build. The full scan reads and parses 200 files at a time in parallel.
- M2: `AttachmentPolicy`, `ImportAttachmentUseCase`, `AttachScreenshotUseCase`, three new ports (attachments, screen capture, workspace) with live, mock and spy versions. `Ports.live` takes the command recorder and builds one `ShellRunner`.
- `check-layers.sh` allows `QLPreviewPanel.shared()` in SlateData and the word `"public"` inside a string literal.
- M1.5 editor spike: the own TextKit 2 core and the `MarkdownEngine` package rendered a 5,000-line note. The own core opens in 71 ms and takes 2.2 ms per keystroke; the package takes 975 ms and 79 ms. Slate keeps the own core (ADR 0005 amendment).
- M1: note codec (header parser and writer, opaque headers kept byte for byte), stem, preview, title, template and conflict policies, twelve use cases, coordinated atomic file store, trash with manifest, config and template files, vault bootstrap, in-memory index, FSEvents watcher with coalescing and own-write filter. 222 tests in 57 suites, among them integration tests over real FSEvents and a concurrent `touch` loop.
- Test spies are in-memory fakes that record their calls; `StoreHarness` builds the stores over them.
- `docs/PLAYBOOK.md` sections 4 and 5 are verified, with the traps found (`/private` paths, rescan batches, stream cancellation).
- `testing` and `panel-window` skills, `ARCHITECTURE.md`, the data rule and `CLAUDE.md` match the M1 code.
- Specification: `docs/SPEC.md`, `docs/STORAGE-FORMAT.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `docs/PLAYBOOK.md`, `docs/BOOTSTRAP.md`, `docs/UX.md`, six ADRs.
- Xcode project with the settings from `docs/BOOTSTRAP.md` section 1 and the local package `Packages/SlateKit` (nine modules, five test targets, one test each).
- `Scripts/`: `build.sh`, `test.sh`, `run.sh`, `install.sh`, `check-layers.sh`, `layer-exceptions.txt`.
- `.claude/`: session brief and changelog hooks, rules (`layers`, `domain`, `data`, `presentation`, `testing`), seven skills copied from DevHub.
- M0: shared UI blocks, hints and formatters, `AppWindows`, `MenuBarPanel`, `WindowLayout`, drag and resize, `Navigator`, `ActivityLog`, `Toaster`, `AppEvents`, `RefreshTask`, `ActionRunner`, `ShellRunner`, `UserDefaultsKeyValueStore` and test helpers copied from DevHub and cleaned of DevHub features.
- M0: `MockVault`, mock and spy ports for the note list and folders, 48 tests in 19 suites.
- `check-layers.sh`: the `UserDefaults` rule matches the whole word only, so the `UserDefaultsKeyValueStore` type name is allowed.
- `panel-window` skill rewritten for Slate; `ui-components` skill and the rules updated for the removed formatters and the new `Ports.spies(keyValues:)`.
