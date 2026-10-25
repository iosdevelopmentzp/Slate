# Changelog

All notable changes to Slate. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Newest first.

Every session that changes code adds lines under **Unreleased** before it ends. One line per user-visible change, described as behaviour, not as files. Scripts, hooks, skills and docs go under **Infrastructure**.

## [Unreleased]

### Added
- Agents: after an install of Slate, a `slate mcp` server that was started before it refuses every call and asks to reconnect it (`/mcp`, slate, Reconnect in Claude Code). Before, such a server kept running the old code until the agent session ended, so an agent could use old tool rules for days.
- Sort the notes of a list: the arrows button next to the folder title has Date Edited (newest first), Date Created (newest first) and Title (A to Z). Pinned notes stay on top. Slate remembers the choice, also after a restart, and uses it for every folder.
- `⌘F` and `⌃F` find in the open note when the note text has the focus, and search all notes anywhere else. `⇧⌘F` always searches all notes. `⌥⌘F` still finds in the note.
- A note opened from search marks every search word in its text in yellow, so you see where the words are. The marks go away when you type, press Esc or open another note.
- Find in Note has a magnifier button next to the note title. It opens the find bar over the text (`⌥⌘F` as before).
- Collapse a section of a note, like in Apple Notes: rest the pointer on a heading and click the arrow on its left. The text under the heading hides until the next heading of the same or a higher level. `⌥⌘←` and `⌥⌘→` collapse and expand the section of the caret; `⇧⌥⌘←` and `⇧⌥⌘→` do it for every section. The commands are in the Edit menu too. Slate remembers the collapsed sections of each note, also after a restart. Only the view changes: the file stays the same.
- Export a note as PDF or HTML: the share button next to the title, or Note → Export as PDF and Export as HTML. The file goes to Downloads and shows in Finder. Images are inside the file, so it works when you send it. `[[links]]` become their text, highlights stay yellow, tables have borders, and the PDF has pages.
- Backlinks: when other notes link to the open note, a small "↩ 3" button shows next to the title. It lists those notes with the line around each link; a click opens the note. Markdown links to a note file, such as `[the plan](Plan.md)`, now count as links too, for backlinks and for `list_backlinks`. The search index is rebuilt once after the update to find them.
- Go to Heading: the list button next to the title, `⇧⌘O`, or Edit → Go to Heading… shows the headings of the note, indented by level, with the current section ticked. Pick one to jump there; the heading flashes once.
- Code blocks have colours again: keywords, strings, comments, numbers and types for Swift, Objective-C, JSON, YAML and shell, added and removed lines for diff, and levels and times for logs. The language shows in the top-right corner of the block; click it to pick another language or Plain text. The language is the word after the opening ``` in the file.
- Highlights and text colours. Select text and use the new colour button in the format bar, the Format menu or the right-click menu: Highlight in yellow, green, blue, pink or purple, or Text Colour in red, orange, green, blue or grey. `⇧⌘E` highlights in yellow. It works in table cells too. In the file a yellow highlight is `==text==`, as in Obsidian; other colours are `<mark>` and `<span>` tags in the format of the Obsidian plugin Highlightr (ADR 0017). Such tags from other tools no longer turn the paragraph into a raw block.
- Tables: a round "+" on the line between two rows or two columns adds a row or a column there. Before, the "+" strips added only at the end, and a row in the middle needed the right-click menu.
- Tables: rows and columns can be moved. Drag the small grip at the left of a row or at the top of a column, press `⌥⌘` with an arrow, or use Move Row Up, Move Row Down, Move Column Left and Move Column Right in the right-click menu. A click on a grip selects the row or the column and opens the menu. The header row stays first.
- A click in a link shows a small bar under it with the address or the note name, and Open, Edit, Copy and Remove buttons. The right-click menu of a link has the same actions, in the text and in table cells.
- The link window has a Text field next to the address, so you can change what a link shows. Link to takes a web address or the name of a note, and completes note names as you type. A note name makes a `[[Note|text]]` link.
- `batch_edit` makes several small changes in one call, in one or more notes. Slate checks all of them first, so when one fails nothing is written, and it keeps one version for the whole batch.
- The Plan of a task note is a checklist that agents can read and change. `set_plan_item` marks a step done by its number or its text, and `project_context` shows for each task how many steps are done and the next step.
- `list_notes` returns the type, status and ticket of task notes, and the headings of each note with `headings: true`.
- Agents can change a small part of a note. `replace_in_note` replaces one exact piece of text, like one table row or `[ ]` to `[x]`. `update_section` replaces the text under one heading. `read_section` reads one section. Before, an agent had to read and write the whole note for every small change.
- `append_to_note` takes `position: top`, for lists that keep the newest entry first, like a changelog.
- `list_backlinks` lists the notes that link to a note with `[[its name]]`.
- `create_note` makes a missing folder, when agents may write there.
- `log_progress` returns the entry as it was written. `attach_image` takes `section` and says where the image went.
- Format JSON: select JSON (or put the caret in a code block) and press `⌥⇧⌘J`, or choose Format JSON in the "…" menu or the Format menu. The text becomes a JSON code block with indented lines, even when it was spread over many paragraphs. One Undo brings the old text back. When the text is not JSON, a toast says so and nothing changes.
- Several carets, as in Xcode: `⌃⇧↑` and `⌃⇧↓` (or Edit → Add Caret Above, Add Caret Below) add a caret on the line above or below, in the same column. Typing, Backspace, Delete, Tab, ⇧Tab and the arrow keys then act at every caret, and one Undo takes back the typing at all of them. Tab indents each list item that has a caret and puts a tab at the other carets. All carets blink together. Backspace at the start of a line does not join it with the line above. Esc, a click, Enter, paste or a format command leave one caret. With one caret the editor works as before.
- Paste JSON or code and it becomes a code block: one block in a monospaced font, with no space between the lines. JSON on one line is split into indented lines; JSON that already has lines keeps them. This also works for code copied from a web page. Plain text stays paragraphs as before.
- A Code block button in the format bar. It turns the selected lines into one code block, and inside a code block it turns the block back into paragraphs. The style is now called Code block instead of Monospaced.
- Attach any file to a note: the paperclip button in the format bar, Format → Attach File or `⇧⌘A`. The file is copied to `_attachments` and the note gets a link with the file name; ⌘-click the link to open it. Before, the button chose only images; dropping and pasting files from Finder worked already.
- The `slate-task` skill in `Skills/slate-task/` for Claude Code: at the start of a session it finds the task of the repository in Slate and says where the last session stopped; it keeps Context, Plan, Findings, Questions and files in the task folder, writes a Log line after each commit, and at the end writes what is done and next, sets the status and saves a version. The README has the line that links it into `~/.claude/skills/`.
- `Scripts/auto-install.sh`: with the `post-commit` and `post-merge` hooks from the README, a commit on `main` that changes code builds Slate and installs it to `/Applications` in the background, with a notification. The Dock, Spotlight and Launchpad always open the last commit.
- `Scripts/quit.sh`: `run.sh` and `install.sh` ask Slate to quit, so it saves the open note first. Before, `pkill` stopped it at once.
- An app icon: a white note with an orange title line on a slate blue square. It shows in Finder, Spotlight, Launchpad and the Dock.
- Versions you can look at (ADR 0015). The clock button of a note shows the versions on the left and, for the one you pick, what changed since then (added lines green, removed lines red) or its whole text, with Restore. Name a version with Save Version, like "before refactor"; it shows in bold with a bookmark, and agents can do the same with `save_version`.
- Changes of a folder: the clock button in the list header shows who changed what and when, with an Agent badge on the changes made by agents, and the notes and files added, changed or removed. Click a note to open it.
- Versions of files: Versions… in the menu of a file shows its earlier versions with Quick Look and Restore. Files larger than 50 MB are not kept.
- Clear History of a folder (in its Changes) or of everything (Settings → General) keeps only the notes and files as they are now. Slate asks first, and the next backup replaces the old history on the remote.
- Agents keep the documentation of their task in Slate. `slate mcp` finds the project of the repository it runs in (also from a git worktree or a fresh clone with the same remote) and tells the agent so when the session starts. Seven new tools: `project_context` (the project, its tasks and the task of the current branch), `start_task`, `set_task_status`, `log_progress` (a dated entry in the Log section), `add_file`, `list_files` and `save_version`. Register the server once for every repository with `claude mcp add -s user slate -- slate mcp`.
- `slate project` shows the project of the current repository and its tasks, `slate project add MyApp --repo .` links a repository, and `slate task new`, `slate task status` and `slate task log` work with a task from the terminal. Link Repository… in the app also stores the remote, and the main checkout when you pick a worktree.
- Import Folder… in the + menu next to Projects, or drop a folder from Finder on the Projects label. Slate copies the folder with its notes, files and sub-folders into a new project and says how many came in. A hidden folder such as `myapp/.slate` gets the name of its repository, and the repository is linked to the project. The original folder does not change.
- Tasks in projects. Right click a project and choose New Task, type `ABC-123 Fix login` and press Enter: Slate makes the task folder and its task note and opens both. The list of a project shows each task with its status (To do, In progress, In review, Done, Dropped), work in progress first. The editor of a task note shows the status as a menu, the ticket and the branch; click the ticket or the branch to copy it. The task note ends with a Log section for the notes of each work session.
- A Files section in every folder lists the files that are not notes: logs, screenshots, PDF, JSON. Each row has a thumbnail or an icon, the size and the date. Double click opens Quick Look, and the "…" menu has Open, Show in Finder, Save to Downloads, Copy Path, Rename and Move to Trash with Undo. Drop files from Finder on the list to copy them into the folder. A file that an agent or another app adds shows up within a second.
- Projects (ADR 0014). A project is a folder for the notes, tasks and files of one code repository. Projects have their own section in the sidebar under the folders, with a + button. Right click a folder and choose Make a Project, or a project and choose Make a Folder; the notes stay where they are. Link Repository… remembers which repository the project belongs to. Agents may change the notes of a new project.
- Change the size of an image (ADR 0013). Drag the grip at the bottom right corner of an image in the text, or right click an image or a cell thumbnail and choose Size. The width is stored the Obsidian way, `![photo|300](…)`, so Obsidian shows the same size.
- Select several table cells: Shift-click, drag across cells, Shift with an arrow at the edge of a cell, or ⌘A twice. Copy, cut, paste a block of cells, clear them with Delete, or make them bold or italic in one step. Align, Delete Rows and Delete Columns in the menu act on the whole selection.
- Wide tables scroll sideways inside the note instead of sticking out on the right. Columns stay at least 120 pt wide, so the text stays readable; swipe sideways on the table or use Shift with the mouse wheel.
- Turn text into a table and back. Select lines and press the Table button or `⌥⌘T`: tabs or `|` split the columns and the first line is the header. Convert to Text in the table's right-click menu gives the lines back, with tabs between the cells.
- Copy Table as Markdown and Copy Table as Text in the right-click menu of a table. The text form has tabs between the cells, so Numbers, Excel and chat apps get a real grid.
- Find in Note (`⌥⌘F`) also finds and replaces text in table cells. Close the find bar on a match in a cell and that cell opens for editing with the match selected.
- The arrow keys enter a table. ↓ from the line above goes to the header row, in the column under the caret; ↑ from the line below goes to the last row; → and ← at the edge of the next line go to the first or the last cell. Before, only a click started editing a cell.
- Save an image to Downloads with one click. Point at an image in the text and press the round button at its top right corner, or right click an image in the text or in a table cell and choose Save to Downloads. The toast says where the copy went; a name that is taken gets a number.
- Several lines of text in one table cell (ADR 0012). Press ⇧Enter in a cell to start a new line; Enter still goes to the cell below. Pasted text keeps its lines. In the file a new line in a cell is `<br>`, which GitHub and Obsidian show the same way, and tables from other apps with `<br>` now open as tables.
- Images in table cells (ADR 0009 level 2, S7). Drop an image on a cell, paste one into a cell, or press the Image button or ⇧⌘S while you type in a cell. The cell shows a thumbnail next to its text; double-click it for Quick Look, and Delete removes it. In the file the cell keeps `![](../_attachments/…)`, and the image links still work when the note moves to another folder depth.
- Tables (ADR 0009, S6). The Table button in the format bar, Format → Table and `⌥⌘T` insert a table with a header and one row. Click a cell to type; bold, italic, strikethrough and links work in a cell. Enter goes down, Tab and Shift-Tab go right and left, and Tab on the last cell or Enter on the last row adds a row. The arrow keys and Esc leave the table. On hover a "+" strip adds a column or a row; the right-click menu adds, aligns and deletes rows and columns, and deletes the table. Column widths follow the text, and long text wraps in the cell. Every cell edit and every change of rows or columns is one step of Undo.
- In the file a table is a GitHub pipe table. A table from another app keeps its exact text until you change it. A table that Slate cannot show (uneven rows, an image in a cell) stays as plain text, as before.
- Copy of a table gives the Markdown table. Pasting a Markdown table makes a table. Edit → Paste as Table turns rows copied from a spreadsheet (tab-separated) into a table.
- AI agents can work with the notes (ADR 0010, S5). `slate mcp` is an MCP server with eleven tools: list_folders, list_notes, search_notes, read_note, create_note, append_to_note, update_note, move_note, trash_note, attach_image and open_in_slate, and the resource `slate://note/<id>`. Add it to Claude Code with `claude mcp add slate -- slate mcp`. Every tool writes through the same code as the app, so the header, the file name and the search stay right. `update_note` refuses a change when the note changed after the agent read it.
- Settings → General → AI access: choose the folders that agents may change (Notes by default), and whether agents may create notes or move notes to the Trash (off by default). The choice is saved in `.slate/agents.json`. The box shows the line to add Slate to Claude Code, with a Copy button.
- Slate keeps a version before and after every change by an agent, with the message `agent: <tool> <title>`, and Activity shows "Changed by an agent: <title>".
- Slate writes a guide for agents into `CLAUDE.md` and `AGENTS.md` at the root of the notes folder, between `<!-- slate:begin -->` and `<!-- slate:end -->`. Your own text outside the markers stays as it is.
- Copy Path and Copy Link in the card menu and in the Note menu. `⌥`-click on the note title copies the path. A card dragged into a terminal, an agent window or Finder carries the note file.
- The welcome note and `Scripts/install.sh` explain how to give notes to an agent.
- Sub-folders at any depth. Right-click a folder and choose New folder inside. The sidebar shows the folders as a tree with arrows that show or hide the sub-folders. A folder lists its sub-folders first and then its own notes; a click on a sub-folder opens it, and the back arrow next to the title goes up again. New notes go into the open sub-folder. Notes move into a sub-folder with the card menu (Move to) or by drag and drop. Rename and delete a sub-folder from its menu; delete moves its notes to the parent folder and offers Undo. Image links in a note still work after it moves to another depth.
- Appearance (Match the system, Light, Dark) is also in the right-click menu of the menu bar icon and in View → Appearance of the window, next to Settings → General.
- Settings → General has "Back up to" for a git address and a "Back up now" button. Slate says "Backed up", or that the backup failed and where to look.
- Moving a note to another folder shows a toast with Undo, which moves it back.
- Esc in the note text closes the panel, like Esc anywhere else in the panel.
- The editor shows formatted text without Markdown marks: titles, headings, bold, italic, strikethrough, code, links, round checkboxes, bullets, numbers, quotes, code blocks, dividers and images in the text. The file stays plain Markdown.
- A format bar above the text: the paragraph style menu (Title, Heading, Subheading, Body, Monospaced), Bold, Italic, Strikethrough, Checklist, Bulleted list, Numbered list, Quote, Link and Image, and a "…" menu with Divider and Screenshot. Active styles are tinted, and every button shows its shortcut.
- Shortcuts and a Format menu: `⇧⌘T` `⇧⌘H` `⇧⌘J` `⇧⌘B` `⇧⌘M` for the paragraph styles, `⇧⌘L` `⇧⌘7` `⇧⌘9` for lists, `⌘'` quote, `⌘B` `⌘I` `⇧⌘X`, `⌘K` link, `⇧⌘I` image, `⇧⌘S` screenshot, `⌘]` and `⌘[` to indent a list item, `⌥⌘F` find in the note.
- Lists behave as in other editors: Enter makes the next item, Enter on an empty item ends the list, Tab and `⇧Tab` indent, Backspace at the start turns the item into text. Typing "- ", "1. ", "[] ", "# " or "> " at the start of a line starts that style.
- Images are blocks of their own: paste, drag, the Image button and `⇧⌘S` put them in the text; double-click opens Quick Look; the right-click menu has Open, Show in Finder and Copy Image.
- `⌘K` on selected text asks for the address in a small popover; `⌘`-click opens a link or a note link.
- Copy writes Markdown and plain text; paste keeps the formatting from Slate and from web pages.
- Folders in the panel and the window: New folder at the bottom of the sidebar or `⇧⌘N` makes a folder and lets you name it at once. Double-click a folder to rename it. Right click for Rename, Colour, Icon, Move up, Move down and Delete folder.
- Delete folder asks in the sidebar first: "Delete "Ideas"? Its 4 notes move to Notes. Yes · No". The notes move to the quick note folder and a toast offers Undo, which brings the folder and its notes back.
- Folder colours: red, orange, yellow, green, teal, blue, purple or pink, saved as `color` in `.slate/spaces.json`.
- Drag a note card onto a folder to move the note there.
- The width of the list is draggable (260 to 420 points, double-click for the default) and remembered, and so is the sidebar (`⌘0` in the panel too).

### Changed
- The agent rules (`CLAUDE.md` and `AGENTS.md` in the notes folder) say that a list item holds only one line and its nested items. An agent had put a table under a list item, and the app then showed the whole list as plain Markdown.
- The note text has 96 pt of empty space below its last line, so the end of a note no longer sits at the bottom edge of the window. A click in that space puts the caret at the end.
- The text of a note is more compact: less space between lines (1.25 instead of 1.4 for body text, 1.2 instead of 1.35 for lists) and between paragraphs. The same note takes about 13 % less height.
- The folder column can be wider: drag its right edge (180 to 300 pt). Slate remembers the width; a double-click on the edge sets the default again. The default width is now 220 pt instead of 200 pt. A folder name that does not fit shows in full in a hint when you rest the pointer on it. The folder title above the list does the same.
- `Scripts/install.sh` signs Slate and the `slate` command with a local certificate when `~/.config/slate/sign-identity` (or `SLATE_SIGN_IDENTITY`) holds its SHA-1 hash. macOS then keeps the access to the Documents folder and other permissions after each install, instead of asking again.
- Slate is a normal window app with a Dock icon, like Terminal or a browser. The window no longer closes when you click outside it, so a file chooser for Attach file or Image no longer closes Slate. The close button and `⌘W` hide the window and give the focus back to the previous app. The Dock icon, the menu bar icon and `⌥⌘N` show the window again on the desktop you are on, with the same note open; when the window is in front, the menu bar icon and `⌥⌘N` hide it. At launch the window is open or hidden as it was when Slate quit.
- The format bar shows Divider, Screenshot and Format JSON as buttons when the window is wide enough. In a narrow window they stay in the "…" menu.
- The quick note field has the soft look: a rounded white card, the folder as a tinted chip on the left and "⏎ Save" on the right.
- Settings → General follows the order of the design: notes folder, login and the quick note folder, appearance and text size, backup and Trash days, Check-up.
- `⌘↑` and `⌘↓` move to the previous and next note when the note text is not being edited, also from the main menu. In the text they go to the start and the end.
- The panel and the window have the same three columns: folders, notes, the note. The header and the footer are gone; the sidebar has Settings and Open as window at the top, the list has the folder name, a round + button and a rounded search field.
- A softer look: notes are rounded cards with a two-line preview, the selected folder and card have a soft tint, the window has no title bar line and the columns have no divider lines.
- Friendly empty states: "Nothing here yet." with a New note button, "Pick a note or press ⌘N.", "No notes match." with Clear search, and "The Trash is empty."
- Markdown Slate cannot show (tables, footnotes, HTML, deep headings) stays as it is, in a monospaced block on a light tint, and is saved without a change.
- The default text size is 15.
- The note title is larger, the text sits in a column up to 720 points wide, and a quiet "Saved" appears for a second after each save.
- The Trash shows cards with Restore and Delete now on hover; Delete now asks "Yes · No" in the card.
- The sort order is always "date changed", with pinned notes first.
- Slate now shows only folders and notes. The menus, the panel, the window, the quick note field and Settings have no other kinds of notes any more.
- A new notes folder starts with one folder, Notes, and the welcome note. Slate no longer writes `_templates/`, `.slate/types/`, `.slate/views.json` or `.slate/actions/`. Folders and files from older versions stay and keep working.
- The quick note field has the folder menu and two keys: Enter saves, `⌘Enter` saves and opens the note. A text that starts with a ticket key is a plain note.
- Settings has two pages: General (notes folder, login, text size, appearance, Trash days, quick note folder, Check-up with Activity) and Shortcuts (Open Slate, Quick note, New note). The New note shortcut has no keys until you set them.
- The status item menu offers New Note, Quick Note, Open Window, Settings and Quit.
- A note card shows its title, date, a two-line preview and the pin. The note header shows the title and the versions button.
- `slate://open` with a title or an id that matches no note says "Slate found no such note".

### Removed
- The panel under the menu bar icon, the "Open as window" button and `⇧⌘O`. The window replaces them.
- Editor: the Markdown marks on screen, code colours, `[[` completion, moving and duplicating lines (`⌥↑` `⌥↓` `⌘D`), commenting code (`⌘/`) and Find and Replace in the menu (the find bar still has Replace).
- Note kinds and the New menu, tasks, ticket and branch chips, status, `⌘⇧D`, Today and daily notes (`⌥⌘T`, `⌘[`, `⌘]`), snippets, meetings, tags and tag chips, Insert Template, saved searches, Open TODOs, the palette (`⌘K`), actions, Copy for Slack, Copy as Markdown, Save as HTML and PDF, Float on Top and note windows, the outline, ticket details, the Links and History pages of Settings, the history and push state and the Activity button in the footer. The files and the command line keep working; the code for them is in commit `545e0d6`.

### Fixed
- A table with a cell that starts with `#`, `-`, `>`, `1.` or a similar mark, for example a `#` column title, showed as raw Markdown on a pink background. Such a cell is now plain text, as on GitHub.
- Agents: a Slate tool no longer ignores an argument it does not know. Before, `create_note` with the text under `text` instead of `body` made an empty note and answered with success. Now every tool checks the names and the types of its arguments first. A wrong name, a missing argument or a wrong type gives one error that names all of them and the arguments the tool takes, and nothing is changed. This also applies to each operation of `batch_edit`. The answer of `create_note` and `update_note` says how many lines the note has, and `create_note` warns when the note is empty.
- A code block or a quote at the very start or end of a note no longer traps the caret. `↑` on its first line (or `←` at its start) opens an empty line above it; `↓` on its last line (or `→` at its end) opens one below it.
- Find in Note: the yellow box over the current match hid the found text. The text now shows in the box, also in code blocks and table cells.
- The file watcher tests and two editor save tests no longer fail when the Mac is busy, for example during an install. They wait for a marker file instead of a fixed second, and the wait limit is 10 s instead of 2 s.
- A click on the menu bar icon brings the Slate window to the front again. Since Slate became a normal window, the window opened behind the active app, for example behind the Terminal. A click on the Dock icon was not affected. The same fix applies to Settings and to the window after a screenshot.
- The link window opens and stays open in a table cell too. The cell stopped editing when the window took the keyboard, and the window closed with it. Bold, Italic, Strikethrough and Link in the format bar now work in a table cell.
- The link window (`⌘K`) no longer closes when you start to type. It did not take the keyboard, so the first letter went into the note and the window closed.
- `slate mcp` no longer stops working after an install. `install.sh` copied the new `slate` over the old file, and macOS killed the new file at start, so Claude Code showed "Failed to connect". The script now copies to a new file and moves it into place.
- `⌘`-click on a link in a table cell opens it, like a link in the text: a web address in the browser, `[[Note]]` in Slate. Before, it only placed the cursor.
- Slate froze when a folder had thousands of sub-folders, for example after importing a code repository. The Move to menu of every note card walked the whole folder tree again and again; the tree is now built once.
- Import Folder… of a git repository root copies only the notes (`.md`), not the code, and skips build folders such as `Pods`, `Carthage`, `node_modules` and `DerivedData`.
- An earlier version of an image or another binary file came back broken: the history read it as text. It now comes back byte for byte.
- Quick Look shows the image again when you open it from the panel. The preview opened under the panel, so it looked empty; now it opens above every Slate window.

### Added
- Float on Top keeps a note in a small window above other apps, for a checklist next to Xcode. Open in New Window (`⌘⇧N`) opens a note in its own window.
- While the window is open, Slate has a menu bar with every command and its shortcut.
- More keys: `⌘1`…`⌘9` and `⌘⇧[` `⌘⇧]` for folders, `⌘⌥↑` `⌘⌥↓` for the previous and next note, `⌘⇧M` to move a note, `⌘⌫` to move it to the Trash, Esc to close the panel.
- Editor: move lines with `⌥↑` and `⌥↓`, duplicate with `⌘D`, comment code with `⌘/`, find and replace in the note, an outline of the headings, backticks in pairs and a closing fence after Enter.
- With an API token in Settings → Links, a task shows the title, status and person of its ticket. The token stays in the Keychain.
- Daily notes can be turned off, carry-over can be turned off, and the daily template can be chosen.
- The Doctor also shows the number of notes, the last version, whether the backup remote answers, and the global shortcuts.
- `⌘K` opens a palette: recent notes when empty, then notes and commands as you type. Enter runs, `⌘Enter` opens in the window, `⌘C` copies the note's path.
- Open TODOs lists every open checkbox in every note, grouped by note or by ticket. Checking one writes the file.
- Saved searches from `.slate/views.json`: Open TODOs, Active tasks, Changed this week, Untagged, Conflicts. Edit the file to add your own.
- `slate://` links: `new`, `open`, `append`, `capture` and `search` work from Terminal, scripts and other apps, also when Slate is not running.
- The `slate` command line tool: `slate new`, `open`, `append`, `today`, `search`, `list` and `path`. It works when Slate is closed.
- Services → Add to Slate turns selected text in any app into a note in Inbox.
- Actions: scripts in `.slate/actions/` run from the note menu or the palette with the note's path, ticket and branch, and put their output in Activity, the clipboard or the note.
- The note menu (`…` next to the title): Copy as Markdown, Copy for Slack, Save as HTML and Save as PDF (into Downloads).
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
- A click on a table cell no longer freezes Slate. The table passed the click on to the cell's text view, which then waited for the mouse forever; now the table puts the caret itself.
- `⌘Z` (Undo) and `⇧⌘Z` (Redo) work in the note text, in the panel and in the window. Before, the editor kept its own undo history but the Undo command did not reach it, and the panel had no Edit keys until the window was opened once.

### Infrastructure
- The `slate-task` skill uses `replace_in_note`, `update_section` and `read_section` for small changes, and `update_note` only when most of a note changes.
- Docs match the phase 2 code: the module tree, the store table and the test list in `docs/ARCHITECTURE.md`, the editor line in `CLAUDE.md` and `.claude/rules/layers.md`, the `panel-window` skill (three columns, sizes, column resizer) and the store rules without `ActionRunner`.
- `README.md` describes v1: what Slate does, the keys, the build scripts and a table of the screenshots the owner takes. `docs/STATUS.md` has the manual checks of S1 to S4 as a numbered list.
- `SlateEditor` is a new TextKit 2 rich text editor (`RichTextEditorView`, `RichTextController`, `RichTextStyler`, `RichLayoutFragment`, `EditorCommands`). The M2 Markdown editor, its highlighter and the `[[` completion are removed. Tests drive the editor in a window: commands, list keys, undo, images, copy and the 5,000-line note (about 1.3 ms per key).
- `SlateEditor` reads Markdown into formatted text and writes it back (`MarkdownReader`, `MarkdownWriter`, swift-markdown under `SlateEditor/Markdown/`). Files Slate wrote come back byte for byte; files from other tools keep the same Markdown tree; anything outside the subset stays as a raw block. Tests: a fixture set and 300 random documents.
- M7: secret store and issue tracker ports (Keychain, Jira REST), `IssueStore`, per-window editor stores, `MainMenuBuilder`, line commands, fence completion and outline in the editor module. CLI tests use their own support folder.
- M6: `Config/Slate-Info.plist` (URL scheme, Services); `AppContainer` is the app delegate; URL command parser, Slack format, action environment policies; toggle todo and run action use cases; action runner and exporter ports; `TodoStore`, `PaletteStore`; a sixth test target, `SlateCLITests`.
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
