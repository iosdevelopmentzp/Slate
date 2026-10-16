# ADR 0001: Files are the source of truth

Status: accepted, 2026-10-16

## Context

A notes app needs fast lists and search, and it needs the user's data to survive the app. The owner is a developer who already reads and writes Markdown in editors, in git and with Claude Code. The owner has no Apple Developer account, so CloudKit is not available. The vault is a local folder (ADR 0002).

## Decision

- A note is one Markdown file with a flat YAML header in a folder the user chooses (the vault). The folder is the database.
- The app keeps a derived SQLite index (FTS5) outside the vault for lists and search. The index can be deleted at any time and is rebuilt from the files.
- Every read of a note's content goes to the file. The index serves summaries, search hits and relations only.
- The format is written down in `docs/STORAGE-FORMAT.md` and stays compatible with Obsidian, so a second editor always exists.

## Consequences

- Other tools (CLI, scripts, Claude Code, Obsidian) can create and edit notes without the app. The app must watch the folder and handle external changes and conflicts explicitly.
- No relational features that need the database to be authoritative (no cross-note transactions). Links resolve by file name through the index.
- Renames rewrite links in other files, which is slower than an id-based database but keeps the files readable.

## Alternatives rejected

- SwiftData or Core Data with CloudKit: needs a developer account; opaque store; hard to use from scripts.
- SQLite as the only store with export: lock-in, no second editor, conflicts on sync are binary.
- One folder per note (note plus assets): harder to grep, incompatible with Obsidian, rename cost is the same.
