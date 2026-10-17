# Storage format

This file is a contract. The app, the CLI, scripts and other editors (Obsidian) all read and write the same files. A change here needs a new ADR in `docs/adr/` and a bump of `schema_version` in the index (section 9).

Vocabulary: the **vault** is the root folder. A **space** is a top-level folder of the vault. A **note** is one `.md` file. The **stem** is the file name without `.md`.

---

## 1. Vault layout

```
Slate/                          the vault (user-chosen folder, default ~/Documents/Slate, ADR 0002)
  Notes/                        space; the only folder a new vault gets (ADR 0007)
  <Folder>/                     every other space the user makes
  _attachments/                 every image and file, flat (section 5)
  _templates/                   optional: one Markdown body per note type (section 6); not created since ADR 0007
  CLAUDE.md, AGENTS.md          the guide for AI agents between the slate:begin and slate:end markers (ADR 0010)
  .slate/                       configuration that syncs with the vault (section 7)
    spaces.json                 written on first launch
    agents.json                 optional: what agents may change through `slate mcp` (section 7.6, ADR 0010)
    links.json                  optional (parked by ADR 0007)
    views.json                  optional (parked by ADR 0007)
    types/<type>.json           optional (parked by ADR 0007)
    actions/<name>.json         optional (parked by ADR 0007)
    prompts/<name>.md
  .trash/                       trashed notes and attachments (section 8)
    manifest.json
    <Space>/<file>.md
    _attachments/<file>
```

Before ADR 0007 a new vault got six spaces: `Inbox`, `Tasks`, `Notes`, `Daily`, `Snippets`, `Archive`. Such vaults stay valid; every folder in them is shown.

Rules:

- A space is any top-level folder whose name does not start with `_` or `.`. Order, icon and default note type come from `.slate/spaces.json`; a folder missing from that file is appended at the end with a default icon.
- Notes are discovered at any depth under a space. Since ADR 0011 the app makes sub-folders at any depth, creates notes in the folder or sub-folder that is open, and moves a note into any folder or sub-folder (`<Space>/<Sub>/<Name>.md`). A folder lists its own notes and its sub-folders. When a note moves to another depth, the app rewrites its links into `_attachments/` to match. Sub-folders have no entry in `.slate/spaces.json`.
- Only `.md` files are notes. Any other file under a space is listed under "Other files" in the space (read-only, open in Finder).
- `CLAUDE.md` and `AGENTS.md` at the root are not notes. Each time the app opens the vault it writes the same block into both, between `<!-- slate:begin -->` and `<!-- slate:end -->`, and writes only when the block differs. Text outside the markers is never changed; a file without the markers gets the block at the end. Deleting the block brings it back at the next start.
- The index, the journal, the git history and the list of agent changes (`agent-changes.jsonl`) live **outside** the vault: `~/Library/Application Support/Slate/<vault-id>/` where `vault-id` is the first 12 hex characters of the SHA-256 of the vault's standardized path. The vault contains only user content and `.slate/`.

---

## 2. Note file

UTF-8, LF line endings. Optional YAML header, then the body.

```markdown
---
id: 9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d
title: ABC-2324 Profile screen leaks memory
type: task
created: 2026-10-16T09:12:33+03:00
updated: 2026-10-16T10:01:02+03:00
tags: [audio, memory]
pinned: false
ticket: ABC-2324
branch: feature/ABC-2324-profile-screen-leaks-memory
mr: https://gitlab.example.com/group/project/-/merge_requests/1234
status: active
---
## Context

Leak after the second call. …
```

### 2.1 Header grammar (a flat YAML subset)

The app reads and writes only this subset. It never needs a YAML library.

- The header starts with a first line that is exactly `---` and ends at the next line that is exactly `---`. No header: the file is a note with the defaults of 2.3.
- Each header line is `key: value`. `key` matches `[a-z][a-z0-9_-]*`. One space after the colon. Empty lines inside the header are allowed and dropped on write. Lines starting with `#` are comments and are dropped on write.
- Values:
  - unquoted string: everything after `: ` to the end of the line, trimmed;
  - quoted string: `"…"` with `\"` and `\\` escapes. The writer quotes a string when it starts with a quote, `[`, `{`, `#`, `*`, `&`, `!`, `|`, `>`, `%`, `@`, `` ` ``, or when it contains `: `, ` #`, or leading or trailing spaces, or equals `true`, `false`, `null`, `~`;
  - boolean: `true` or `false`;
  - date-time: ISO 8601 with offset, `2026-10-16T10:01:02+03:00`. Written with the local offset at write time;
  - list: `[a, b, "c d"]`, items are strings with the same quoting rules. An empty list is `[]`;
  - null: nothing after the colon.
- **Unknown keys are preserved.** The parser keeps the raw line of every key it does not know and writes it back unchanged, after the known keys, in the original order.
- **Opaque header.** If a line inside the header is not `key: value` (nested map, `|` block, `>` block, anchor, a `- item` list), the whole header is marked opaque: the app reads what it can, shows the note, edits the body, and **writes the header back byte for byte**. The header fields are read-only in the UI with the hint "Header uses YAML the app does not edit".

### 2.2 Known keys

| Key | Type | Required | Notes |
|---|---|---|---|
| `id` | string | written by the app | UUID v4, lowercase. Added on the first save of a file that lacks it. Never changed |
| `title` | string | yes when the app writes | Equals the stem on creation; section 3 says when they differ |
| `type` | string | no | `note` (default), `task`, `daily`, `snippet`, `meeting`, or a user type from `.slate/types/` |
| `created` | date-time | written by the app | File creation date when missing |
| `updated` | date-time | written by the app | File modification date when missing. Refreshed only when the header or the body changed |
| `tags` | list | no | Lowercase, `[a-z0-9_/-]+`. Merged with `#tags` from the body for display and search; the header list is the one the app edits |
| `pinned` | boolean | no | Default `false` |
| `ticket` | string | task | Free string; the tracker pattern in Settings validates it for the chip |
| `branch` | string | task | |
| `mr` | string | task | A URL or a short form like `!1234` |
| `status` | string | task | `todo`, `active`, `review`, `done`, `dropped`. Default `todo` |
| `language` | string | snippet | Code fence language of the main block |
| `aliases` | list | no | Other names that resolve a wikilink to this note |
| `due` | date | no | `YYYY-MM-DD`, P2 |

Written order: `id`, `title`, `type`, `created`, `updated`, `tags`, `pinned`, `ticket`, `branch`, `mr`, `status`, `language`, `aliases`, `due`, then unknown keys. Keys with a null value are omitted, except `title`.

### 2.3 Defaults for a file without a header

`type: note`, `title` = stem, `created` and `updated` = file dates, no id. The app adds a header only when it **saves** that note for the first time. Indexing never writes to a file.

### 2.4 Body

CommonMark plus GitHub extensions as understood by Apple's `swift-markdown`: task list items, fenced code with info string, strikethrough, tables (shown as monospace in v1). Plus:

- Wikilinks `[[Stem]]`, `[[Stem|alias]]`, `[[Space/Stem]]`, `[[Stem#Heading]]`.
- Inline tags `#tag` (a `#` followed by `[a-z0-9_/-]+`, not inside a code span or fence, not at the start of a line followed by a space, which is a heading).
- Link patterns from `.slate/links.json` (section 7.2) apply to plain text outside code.

The app never rewrites body text it did not type, except: checkbox toggles (`[ ]` ↔ `[x]` in place), wikilink rewrites on a rename (section 3.3), appends (section 4), and template insertion.

---

## 3. Title and file name

### 3.1 Sanitising a title into a stem

```
func stem(forTitle title: String) -> String
  1. trim whitespace
  2. replace "/" and ":" with "-"
  3. remove \ * ? " < > | and control characters
  4. collapse runs of whitespace into one space
  5. trim leading and trailing spaces and dots
  6. cut to 120 characters on a grapheme boundary, then trim again
  7. empty → "Untitled"
```

Unique within the destination folder, case-insensitively: `Name`, `Name 2`, `Name 3`, …

### 3.2 On creation

`stem = unique(stem(forTitle: title))`, `title` written as typed (not sanitised). A note created with no title gets `title: Untitled`, and the first non-empty body line becomes the title on the first autosave (the file is renamed by the same rule) until the user edits the title by hand.

### 3.3 On a title change (rename)

Runs when the title field commits: focus leaves it, Enter, or 1.5 s without typing.

1. `newStem = stem(forTitle: newTitle)`. If `newStem` equals the current stem (case-insensitively), only `title:` changes.
2. Otherwise `newStem = unique(newStem)`, the file is moved (coordinated move, same folder), `title:` is written.
3. Every note that the index lists as linking to the old stem gets its wikilinks rewritten: `[[Old]]` → `[[New]]`, `[[Old|alias]]` → `[[New|alias]]`, `[[Old#H]]` → `[[New#H]]`, `[[Space/Old]]` → `[[Space/New]]`. Each file is rewritten through the normal coordinated save. A file that cannot be rewritten (conflict, missing) is reported in the activity log with its path; the rename is not rolled back.
4. The index updates the stem, the title and the links.

Daily notes do not rename: their stem is the date.

### 3.4 Resolving a wikilink

Target text `T` (before `|` and `#`):

1. `Space/Stem` form: the file `<Space>/<Stem>.md` or nothing.
2. Otherwise all notes whose stem equals `T` case-insensitively, then all notes with `T` in `aliases`.
3. Several candidates: prefer the same space as the linking note, then the most recently updated.
4. No candidate: the link is unresolved. A click creates `<current space>/<stem(forTitle: T)>.md` with `title: T`.

---

## 4. Appending to a section

Used by Today's log, `slate append` and `slate://append`.

```
append(text, toSection heading: String?, in note)
  if heading is nil → append "\n" + text + "\n" at the end of the body
  find the first heading line whose text equals heading (case-insensitive, any level, outside code fences)
  if not found → append "\n## <heading>\n\n" + text + "\n" at the end
  else → the section ends before the next heading of the same or a higher level, or at the end of the file;
         trim trailing blank lines of the section, insert "\n" + text + "\n" there,
         keep exactly one blank line before the next heading
```

Today's log line format: `- HH:mm text` (24-hour local time). Multi-line text is indented by two spaces under the bullet.

---

## 5. Attachments

- Folder: `_attachments/` at the vault root, flat.
- File name: `yyyyMMdd-HHmmss-<source>.<ext>`, where `<source>` is `screenshot`, `window`, `paste`, or the sanitised original file stem cut to 40 characters. A collision appends `-2`, `-3`.
- Link written into the note: a relative path from the note's folder, `../_attachments/<file>` for a note at depth 1. Images use `![](path)`; other files use `[<original name>](path)`. Spaces in the path are percent-encoded (`%20`).
- A reference is any Markdown link or image whose target resolves inside `_attachments/`.
- "Clean attachments" (command): every file in `_attachments/` with no reference in the index is moved to `.trash/_attachments/` and listed in the manifest. Never automatic.
- Maximum size written by paste: 50 MB; larger files are linked in place with an absolute `file://` URL and a warning.

---

## 6. Templates

`_templates/<type>.md` is the body of a new note of that type. Built-in templates are written on first launch when the file is missing; the user edits them freely. Placeholders, replaced on creation:

| Placeholder | Value |
|---|---|
| `{{title}}` | the note title |
| `{{date}}` | `YYYY-MM-DD` local |
| `{{time}}` | `HH:mm` local |
| `{{datetime}}` | ISO 8601 local with offset |
| `{{ticket}}`, `{{branch}}`, `{{mr}}` | header fields, empty when unset |
| `{{weekday}}` | English weekday name |
| `{{cursor}}` | removed; the caret lands here. Missing: the caret lands at the end |

Built-in bodies:

```markdown
<!-- task.md -->
## Context

{{cursor}}

## Plan

- [ ] 

## Findings

## Links

## Questions
```

```markdown
<!-- daily.md -->
## Log

{{cursor}}

## Notes
```

```markdown
<!-- meeting.md -->
**Attendees:** {{cursor}}

## Agenda

## Decisions

## Actions

- [ ] 
```

```markdown
<!-- snippet.md -->
```{{language}}
{{cursor}}
```
```

`note.md` is empty. The "Carried over" section of a daily note is inserted by the app directly after the header, before the template body, only when at least one item is carried.

---

## 7. Configuration in `.slate/`

All files are JSON with a top-level `"version": 1`. Unknown keys are ignored and preserved when the app writes the file. The app writes a config file only through its Settings UI or on first launch when the file is missing.

### 7.1 `spaces.json`

```json
{
  "version": 1,
  "spaces": [
    { "folder": "Notes", "icon": "folder.fill", "color": "blue", "defaultType": "note" }
  ],
  "captureSpace": "Notes",
  "archiveSpace": "Notes",
  "dailySpace": "Daily"
}
```

`color` is one of `red`, `orange`, `yellow`, `green`, `teal`, `blue`, `purple`, `pink`; missing means `blue`. A folder on disk that is missing from the list is appended with `folder.fill`, `blue`, `note`. Deleting a folder in the app moves its notes to `captureSpace` and removes the entry.

### 7.2 `links.json`

```json
{
  "version": 1,
  "patterns": [
    { "id": "jira",         "regex": "\\b([A-Z][A-Z0-9]+-\\d+)\\b",  "url": "https://example.atlassian.net/browse/$1", "label": "$1", "icon": "ticket" },
    { "id": "gitlab-mr",    "regex": "(?<![\\w/])!(\\d+)\\b",       "url": "https://gitlab.example.com/group/project/-/merge_requests/$1", "label": "!$1", "icon": "arrow.triangle.merge" },
    { "id": "gitlab-issue", "regex": "(?<![\\w/&#])#(\\d+)\\b",     "url": "https://gitlab.example.com/group/project/-/issues/$1", "label": "#$1", "icon": "circle.dotted" }
  ]
}
```

`regex` is an ICU pattern as `NSRegularExpression` reads it. `$1` to `$9` in `url` and `label` are capture groups. Patterns apply outside code spans, code fences and existing links. The first launch writes this file from Settings H2 (tracker and GitLab base URLs).

### 7.3 `views.json`

```json
{
  "version": 1,
  "views": [
    { "id": "open-todos",   "title": "Open TODOs",        "icon": "checklist",        "query": "is:todo" },
    { "id": "active-tasks", "title": "Active tasks",      "icon": "bolt",             "query": "type:task status:active" },
    { "id": "this-week",    "title": "Changed this week", "icon": "clock",            "query": "after:-7d" },
    { "id": "untagged",     "title": "Untagged",          "icon": "tag.slash",        "query": "-has:tag" },
    { "id": "conflicts",    "title": "Conflicts",         "icon": "exclamationmark.triangle", "query": "is:conflict" }
  ]
}
```

`query` uses the search language of `SPEC.md` section 6.1. `after:-7d` is a relative date.

### 7.4 `types/<type>.json`

```json
{
  "version": 1,
  "type": "task",
  "title": "Task",
  "icon": "checkmark.circle",
  "defaultSpace": "Tasks",
  "fields": ["ticket", "branch", "mr", "status"],
  "titlePattern": "{{ticket}} {{title}}",
  "branchPattern": "feature/{{ticket}}-{{slug}}",
  "statuses": ["todo", "active", "review", "done", "dropped"],
  "doneStatuses": ["done", "dropped"]
}
```

`slug` is the title without the ticket, lowercased, non-alphanumerics replaced by `-`, cut to 48 characters.

### 7.5 `actions/<name>.json`

```json
{
  "version": 1,
  "title": "Open worktree in Terminal",
  "icon": "terminal",
  "command": "~/.slate/bin/open-worktree.sh",
  "when": "hasBranch",
  "output": "activity"
}
```

`when`: `always`, `task`, `hasBranch`, `hasTicket`, `hasMR`. `output`: `activity`, `appendToNote` (appended at the end of the body as a fenced `log` block), `clipboard`. Environment given to the command: `SLATE_VAULT`, `SLATE_NOTE_PATH`, `SLATE_NOTE_TITLE`, `SLATE_TICKET`, `SLATE_BRANCH`, `SLATE_MR`, `SLATE_STATUS`. The command runs with the vault as the working folder and a 60 s timeout.


### 7.6 `agents.json` (ADR 0010)

```json
{
  "version": 1,
  "writableFolders": ["Notes"],
  "allowCreate": true,
  "allowTrash": false
}
```

Read by `slate mcp` before every tool call and written by Settings → General → AI access. A missing file or a missing key means the values above. `writableFolders` holds folder paths; a folder allows its sub-folders too, case does not matter. Folders that start with `.` or `_` are never writable. Unknown keys are kept on save. The `slate` command itself does not read this file.
---

## 8. Trash, temporary files, atomic writes

### 8.1 Trash

- A trashed note moves to `.trash/<original sub-path>`; its attachments stay in `_attachments/` (they may be shared).
- `.trash/manifest.json`: `{ "version": 1, "items": [ { "path": "Tasks/Old.md", "originalPath": "Tasks/Old.md", "trashedAt": "2026-10-16T10:01:02+03:00" } ] }`. A file found in `.trash/` without a manifest entry gets an entry with `originalPath` under `Inbox/` and `trashedAt` = its modification date.
- Restore moves the file back to `originalPath` (unique name on collision) and removes the entry.
- Auto-empty: at launch and once per day, every item older than the retention (Settings, default 30 days) is moved to the macOS Trash with `NSWorkspace.recycle` and removed from the manifest.

### 8.2 Temporary files and ignored names

- The app writes through `<folder>/.<name>.slate-tmp` then replaces. Any `*.slate-tmp` older than one hour is deleted at launch.
- Ignored by the scanner and the watcher: `.DS_Store`, `*.slate-tmp`, `.git`, `.obsidian`, anything under `.trash/` except through the trash feature.
- `.<name>.icloud` is an iCloud placeholder for `<name>` that is not downloaded. The scanner lists it as the note `<name>` in state "in cloud" (title from the stem, no body, no header). Opening it starts the download.

### 8.3 Write rules

Every write of a vault file:

1. `NSFileCoordinator.coordinate(writingItemAt: url, options: .forReplacing)`.
2. Inside the block: write the bytes to the temp name in the same folder, then `FileManager.replaceItemAt(url, withItemAt: tmp)` with default options (keeps the creation date of the original).
3. Record `(path, sha256)` in the "own writes" set for two seconds, so the watcher does not treat the event as an external change.
4. Update the index for that path in the same operation.

Every read: `coordinate(readingItemAt:options: [])`, then read the bytes and compute the SHA-256. The hash is kept with the open note for the conflict check (`SPEC.md` 5.7).

Moves and renames: `coordinate(writingItemAt: from, options: .forMoving, writingItemAt: to, options: .forReplacing)` and `item(at:didMoveTo:)` inside the block.

---

## 9. Search index

SQLite through GRDB, file `~/Library/Application Support/Slate/<vault-id>/index.sqlite`, WAL mode, busy timeout 2 s. Derived data: deleting the file is always safe.

```sql
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
-- keys: schema_version (integer, starts at 1), vault_path, last_full_scan

CREATE TABLE notes (
  id TEXT PRIMARY KEY,            -- header id, or "path:" + path for a file without id
  path TEXT NOT NULL UNIQUE,      -- relative to the vault, e.g. Tasks/ABC-2324 Profile screen leaks memory.md
  space TEXT NOT NULL,
  stem TEXT NOT NULL,
  title TEXT NOT NULL,
  type TEXT NOT NULL,
  status TEXT, ticket TEXT, branch TEXT, mr TEXT,
  pinned INTEGER NOT NULL DEFAULT 0,
  created REAL NOT NULL, updated REAL NOT NULL,   -- unix seconds
  mtime REAL NOT NULL, size INTEGER NOT NULL, hash TEXT NOT NULL,
  preview TEXT NOT NULL,          -- first 200 characters of the body without Markdown marks
  open_todos INTEGER NOT NULL DEFAULT 0,
  attachment_count INTEGER NOT NULL DEFAULT 0,
  has_code INTEGER NOT NULL DEFAULT 0,
  has_image INTEGER NOT NULL DEFAULT 0,
  has_link INTEGER NOT NULL DEFAULT 0,
  header_opaque INTEGER NOT NULL DEFAULT 0,
  in_cloud INTEGER NOT NULL DEFAULT 0,
  in_conflict INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX notes_space_updated ON notes(space, updated DESC);
CREATE INDEX notes_stem ON notes(stem COLLATE NOCASE);
CREATE INDEX notes_ticket ON notes(ticket);

CREATE TABLE tags (note_id TEXT NOT NULL, tag TEXT NOT NULL, PRIMARY KEY (note_id, tag));
CREATE TABLE links (from_id TEXT NOT NULL, target TEXT NOT NULL, kind TEXT NOT NULL);
  -- kind: wiki (target = stem or Space/Stem), url, pattern:<id>
CREATE INDEX links_target ON links(target COLLATE NOCASE);
CREATE TABLE todos (note_id TEXT NOT NULL, line INTEGER NOT NULL, text TEXT NOT NULL, done INTEGER NOT NULL, due TEXT);
CREATE TABLE attachments (note_id TEXT NOT NULL, file TEXT NOT NULL);

CREATE VIRTUAL TABLE notes_fts USING fts5(
  note_id UNINDEXED, title, body, tags, ticket,
  tokenize = "unicode61 remove_diacritics 2 tokenchars '_-'"
);
```

Rules:

- Full scan: enumerate the vault, skip ignored names, for every `.md` compare `(mtime, size)` with the row; on a difference read the file, compute the hash; on a different hash parse and replace the row, its tags, links, todos, attachments and FTS row (delete then insert, in one transaction per file). Rows whose path no longer exists are deleted. A full scan runs at launch in the background and on "Rebuild index" (which first deletes the file).
- Incremental: the watcher delivers paths; each path goes through the same compare-and-replace.
- Parsing for the index uses `swift-markdown` on the body: headings, task list items (`todos`), links and images (`links`, `attachments`, `has_*`), code blocks (`has_code`), inline `#tags` from text nodes, and the preview text from the first paragraphs.
- Search: `notes_fts MATCH ?` with a MATCH string built by the app, never raw user input: each word becomes `"word"*` (quotes doubled inside), a quoted phrase becomes `"phrase"`, joined with spaces (AND). Rank: `bm25(notes_fts, 0, 10.0, 1.0, 4.0, 8.0)`. Snippet: `snippet(notes_fts, 2, '', '', '…', 12)` with the match range recomputed in the app for highlighting. Filters from `SPEC.md` 6.1 become `WHERE` clauses on `notes`, `tags`, `todos`.
- `schema_version` differs from the app's constant → delete the index file and rebuild.

---

## 10. Compatibility notes

- Obsidian opens the vault as is. Wikilinks by stem, `_attachments/` relative links, YAML header, task lists all work there. Obsidian's own `.obsidian/` folder is ignored by Slate.
- iA Writer, VS Code, `grep`, `rg` and Claude Code read and write the files directly; the watcher picks up the change.
- Files written by other tools without an `id` get one on their first save in Slate. Until then they are identified by path in the index.

---

## 11. The editor's Markdown subset (ADR 0008)

The rich text editor reads any Markdown but writes only this subset. A construct outside it is kept as a raw block and written back unchanged.

| On screen | In the file |
|---|---|
| Title | `# text` |
| Heading | `## text` |
| Subheading | `### text` |
| Body paragraph | the text; paragraphs separated by one blank line |
| Monospaced block | a fenced block: ```` ``` ```` (the original language word kept when the file had one) |
| Quote | `> ` before each line |
| Bulleted list, levels 0 to 2 | `- item`, nested with two spaces per level |
| Numbered list, levels 0 to 2 | `1. item`, renumbered on save |
| Checklist | `- [ ] item`, `- [x] item` |
| Image block | `![](../_attachments/<file>)` on its own line, alt text kept when present |
| Divider | `---` |
| Bold, italic, strikethrough, inline code | `**x**`, `*x*`, `~~x~~`, `` `x` `` |
| Link | `[text](url)`; a wikilink `[[Name]]` in a file is shown as a link and written back as a wikilink |
| Table (S6, ADR 0009) | a GFM pipe table: header row, alignment row with `:` markers kept, one line per row, `\|` for a pipe inside a cell; cells hold inline content only. A table that the editor did not change is written back exactly as read; a changed table is written as `\| a \| b \|` with `---`, `:---`, `:---:` or `---:` markers. A table with uneven rows, without an alignment row, or with an image or other block content in a cell stays a raw block |
| Raw block | the source lines exactly as read |

Rules: LF line endings, one trailing newline, no trailing spaces, the header untouched (section 2). A file written by Slate reads back to the same attributed text and writes back byte for byte; a test guards this over the fixture set.
