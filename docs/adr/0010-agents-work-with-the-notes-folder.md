# ADR 0010: Agents work with the notes folder through documented rules, the CLI and an MCP server

Status: accepted, 2026-10-17. Built in milestone S5 (2026-10-17) with the official MCP package; see `docs/STATUS.md` decisions 105 to 115.

## Context

Notes are plain Markdown files in a local folder (ADR 0001, ADR 0002). An AI agent such as Claude Code can already read and write them with ordinary file tools, and the `slate` CLI (`new`, `open`, `append`, `search`, `list`, `path`, `--json`) and the `slate://` scheme exist from M6. The watcher re-indexes external edits and the "Changed on disk" banner protects a note that is open in the editor.

The owner wants more: to hand a note to an agent easily, to let agents keep some notes up to date on their own, and to have agents know which tools and rules exist. Today an agent that edits a file by hand can break the header, name an attachment wrongly, or write outside the Markdown subset.

## Decision

Three layers, each useful on its own.

### 1. The folder documents itself

- On first launch, and whenever the app version changes, Slate writes `CLAUDE.md` at the root of the notes folder and `AGENTS.md` as a copy of it, between the markers `<!-- slate:begin -->` and `<!-- slate:end -->`. Text outside the markers belongs to the user and is never touched; a file without markers gets the block appended.
- The block says, in plain English: what the folder is; the layout (`<Folder>/<Note>.md`, `_attachments/`, `.slate/`, `.trash/`); the header format and which keys the app owns; the Markdown subset the editor writes and that other constructs stay as raw blocks; the rules (keep the header, never write into `.slate/` or `.trash/`, name attachments as section 5 of the storage format says, prefer `slate new` and `slate append` over writing a new file by hand, write a whole file in one operation); the CLI reference with one example per command and `--json`; how to open a note in Slate (`slate open`, `slate://open?id=`); the MCP server and how to register it (layer 3); what the agent must not do (delete files, touch other folders, store secrets).
- Claude Code reads `CLAUDE.md` when started in the folder or when the folder is added with `--add-dir`. Other agents read `AGENTS.md`.

### 2. Handing a note to an agent

- The note menu gets **Copy path** (absolute file path) and **Copy link** (`slate://open?id=<id>`). `⌥`-click on the title copies the path too.
- A note card can be dragged out of Slate as a file URL (`NSItemProvider` with the file), so dropping it into a Claude Code window, a terminal or a chat inserts the path.
- The welcome note shows these three gestures in one line.

### 3. An MCP server, `slate mcp`

- A subcommand of the existing `slate` executable: a Model Context Protocol server over stdio, built on the official `modelcontextprotocol/swift-sdk` package (a dependency of `SlateCLI` only). If that package does not build with the project's toolchain at the time of S5, the fallback is a hand-written stdio JSON-RPC server with the four MCP methods the tools need; the decision is recorded in `docs/STATUS.md`.
- Registration: `claude mcp add slate -- slate mcp` (the install script prints the line). Claude Desktop and other MCP clients use the same command.
- Tools (names are the contract; every description is one or two plain sentences; errors are plain sentences that say what to do):

| Tool | Input | Does |
|---|---|---|
| `list_folders` | — | folders with note counts |
| `list_notes` | `folder?`, `limit?` | summaries: id, title, folder, updated, pinned, preview |
| `search_notes` | `query`, `folder?`, `limit?` | the app's search: titles and text, snippets |
| `read_note` | `id` or `path` | the whole file (header and body) plus `hash` |
| `create_note` | `folder`, `title`, `body?` | through `CreateNoteUseCase`: header, unique file name, index; returns id and path |
| `append_to_note` | `id`, `text`, `section?` | through `AppendToNoteUseCase` (`STORAGE-FORMAT.md` section 4) |
| `update_note` | `id`, `body`, `expectedHash` | replaces the body through `SaveNoteUseCase`; refuses with "the note changed since you read it, read it again" when the hash differs |
| `move_note` | `id`, `folder` | through `MoveNoteUseCase` |
| `trash_note` | `id` | through `TrashNoteUseCase`; off by default (permissions below) |
| `attach_image` | `id`, `base64 or path`, `caption?` | imports into `_attachments/` and appends the image block |
| `open_in_slate` | `id` | opens the note in the app through `slate://open` |

- Resources: `slate://note/<id>` returns the note text, so a client can attach a note as context without a tool call.
- Every write goes through the same use cases as the app, so the header, the file name, the attachment name and the index are right by construction. The app's watcher shows the change within a second; an open editor reloads when it has no unsaved edits, else the banner appears.

### 4. Permissions and a visible trail

- `.slate/agents.json`: `{ "version": 1, "writableFolders": ["Notes"], "allowCreate": true, "allowTrash": false }`. The MCP server reads it on every call. A write outside `writableFolders` fails with "Agents may not change notes in <folder>. Allowed: …". The CLI stays unrestricted: it is the owner's own tool and the owner's scripts.
- Settings → General gets an **AI access** box: a checklist of folders agents may change, "Allow agents to create notes", "Allow agents to move notes to the Trash", and the registration line with a Copy button.
- Every MCP write takes a git snapshot at once with the message `agent: <tool> <note title>` and adds an Activity line "Changed by an agent: <title>". The clock button on the note shows these versions like any other; Restore undoes an agent's change in one click.
- No new header key: provenance lives in the versions and in Activity, so the storage format does not change.

### 5. Safety limits

- The server listens on stdio only. No network port, no token, no access to the Keychain.
- Every path is resolved and checked to lie inside the notes folder; `.slate/`, `.trash/` and `_templates/` are never writable through tools.
- No tool runs a shell command or an action from `.slate/actions/`; agents that need that use their own shell.
- Attachments: images only in `attach_image` (PNG, JPEG, GIF, HEIC, WebP), at most 50 MB.

## Consequences

- An agent that opens the folder knows the rules; an agent with the MCP server cannot break the format at all.
- The owner can hand over a note by drag, path or link, and can limit agents to a folder such as `AI` while keeping the rest read-only.
- One more dependency in `SlateCLI` (the MCP SDK), none in the app.
- Later options this leaves open: App Intents for Shortcuts and Siri over the same use cases; a "Ask Claude about this note" action through the local `claude` CLI (SPEC G6); a `slate watch` command that streams changes to a client.

## Alternatives rejected

- Only file tools and no rules: works until the first broken header.
- A local HTTP server: a port, a token, firewall prompts, and nothing MCP clients do not already give.
- A plugin inside the app that talks to a model: an API key in the app, a second UI, and against the "app knows no project" rule.

## Milestone S5: agents and the notes folder

Scope: the `CLAUDE.md` / `AGENTS.md` block with its writer and marker rules; Copy path, Copy link, `⌥`-click, card drag-out; `slate mcp` with the eleven tools and the note resource; `.slate/agents.json`; the AI access box in Settings; snapshot and Activity line per agent write; `Scripts/install.sh` prints the registration line; the welcome note line.

Tests: `AgentGuideWriterTests` (markers kept, user text kept, version bump rewrites the block), `AgentPermissionsTests` (folder rules, create and trash flags, path escapes rejected), `MCPToolTests` over a temporary vault for every tool (happy path, hash conflict, forbidden folder), `NoteDragTests` for the file URL provider, round-trip of `attach_image`.

Done when: `claude mcp add slate -- slate mcp`, then in Claude Code "add a line to my note Groceries" appends through `append_to_note` and the line shows in the open editor within a second; `update_note` with a stale hash is refused with the plain sentence; a write to a folder outside the list is refused and shows up nowhere; dragging a card into a terminal inserts the path; a fresh folder has `CLAUDE.md` with the block and the owner's own lines above it survive an app update.
