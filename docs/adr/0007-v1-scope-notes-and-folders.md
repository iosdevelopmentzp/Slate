# ADR 0007: v1 is notes in folders, nothing else visible

Status: accepted, 2026-10-16. Narrows the scope of `SPEC.md` for the first usable version.

## Context

Milestones M0 to M7 built the whole specification: note kinds, tasks with tickets, daily notes, snippets, tags, saved searches, templates, actions, a palette, a CLI, a URL scheme, history. The owner tried the result and found it complex: too many concepts on screen, folders hard to find and impossible to delete, formatting by Markdown marks instead of buttons, images not in the text. The owner asked for a simpler system first: notes, grouped in folders, with an editor that formats like Apple Notes.

## Decision

- **v1 shows two concepts: Folders and Notes.** Plus the search field, the quick note hotkey, pin, Trash, and one Settings window.
- **Parked** (not visible anywhere in the app, not in menus, not in the status item menu, not in the capture field, not in Settings): note kinds, tasks and tickets, branches and merge requests, daily notes and Today, snippets, meetings, tags, saved searches, Open TODOs, templates and Insert Template, actions, the palette (`⌘K`), link patterns and chips, the Links settings page, the History settings page, Copy for Slack and the export menu, Float on Top. Their Domain and Data code and tests stay in the package; their Presentation code is removed. They can return one by one later, each behind its own decision.
- **Kept but quiet:** git versions keep running with the defaults (interval, no remote) and show as the clock button on a note plus a "Back up to" field under Settings → General; the `slate` CLI and the `slate://` scheme keep working for `new`, `open`, `append` and `search` because they are invisible; the Services menu entry stays.
- **Folders become first class:** create, rename, delete, reorder and pick an icon and a colour, in the panel and the window alike (`UX.md` section 2). Deleting a folder moves its notes to the default folder and says so.
- **The first launch creates one folder, `Notes`,** plus `_attachments/`, `.slate/spaces.json` and the welcome note. No `Tasks`, `Daily`, `Snippets`, `Archive`, no `_templates/`, no `.slate/types/`, `views.json`, `links.json` or `actions/`. A folder that exists on disk is still shown; a note with a kind other than `note` is still a note.
- **The editor becomes rich text** with a format bar; ADR 0008 replaces ADR 0005.
- `STORAGE-FORMAT.md` does not change except the default folder set (section 1) and the `color` key of `spaces.json` (section 7.1). Files written by the earlier milestones stay valid.

## Consequences

- The app gets simpler to learn and the surface to polish gets smaller.
- The developer features are one decision away, not one rewrite away: the storage format and the Domain code carry them.
- The spec stays the long-term description; `SPEC.md` section 0.9 marks what v1 includes.
