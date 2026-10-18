# ADR 0014: Projects, task folders and files

Status: accepted, 2026-10-18. Widens ADR 0007 (v1 scope) for projects only. Built in milestones S8 and S9 (`docs/ROADMAP.md`).

## Context

The owner works on code in several repositories. An AI agent such as Claude Code does a task in one of them and loses its context when the session ends. The owner wants three things:

1. The agent keeps the documentation of the task (context, plan, findings, a log of each session) in one place, so the next session continues from it.
2. The owner reads all of that documentation in Slate.
3. Files that belong to a task (logs, screenshots, PDF, JSON) sit next to its notes and can be seen in Slate.

The owner chose to keep this documentation in the notes folder, not inside each repository. One folder means one index, one search, one backup and one history. No file of Slate appears in a work repository.

## Decision

### 1. A project is a top-level folder with project details

- A project is an ordinary top-level folder of the notes folder. Its entry in `.slate/spaces.json` has a `project` object: `{ "id": "<uuid>", "repositories": ["/Users/me/dev/myapp"], "remote": "git@gitlab.example.com:group/myapp.git" }`. Only `id` is required. Unknown keys inside it are kept.
- `repositories` are paths on this Mac. `remote` is the `origin` URL of the repository. Both let the CLI and the MCP server find the project of a working directory, also from a git worktree or a fresh clone (S9).
- A folder can become a project and a project can become a folder again (right-click menu: Make a Project, Make a Folder). The notes do not move. Link Repository… stores the path of a repository.
- A new project has the `shippingbox.fill` icon, and agents may change notes in it (`.slate/agents.json`, ADR 0010).
- The sidebar shows projects in their own section, Projects, under the folders. Move up and Move down move a row inside its own section.

### 2. A task is a sub-folder with one task note

- A task folder sits directly in a project: `<Project>/<ABC-123 Short title>/`.
- Its task note has the same name as the folder and `type: task` in the header, with `ticket`, `branch` and `status` (`todo`, `active`, `review`, `done`, `dropped`). The body starts from the task template with a `## Log` section at the end.
- Other notes and files of the task live in the same folder.
- Inside a project, the list shows a task folder with its status, ticket and branch, and the editor shows them in one line under the title of a task note. Outside projects nothing changes: rule 9 of `UX.md` section 9 still holds there.

### 3. Files in a folder

- Any file under a folder that is not a `.md` note is shown in a Files section of that folder, in every folder and not only in projects: icon or thumbnail, name, size, date.
- Quick Look, Open, Show in Finder, Save to Downloads, Rename and Move to Trash work on a file. Dropping a file from Finder onto the list copies it into the open folder.
- Images pasted into a note still go to `_attachments/` (section 5 of the storage format).

## Consequences

- No new storage root, no change to the index or the watcher. A project is visible to other tools as a plain folder.
- Status, ticket and branch come back from the parked list of ADR 0007, but only inside projects.
- The storage format changes in `.slate/spaces.json` (the `project` object) and gains a task note layout. Old files stay valid.

## Alternatives rejected

- A `.slate/` folder inside each repository, shown by Slate as a second root: agents write there with their own file tools, but the app needs several roots for the index, the watcher, the Trash, history and images. The folder must also be hidden from git, and a git worktree does not have it.
- A separate `.slate/projects.json`: a second file that must follow every rename of a folder. The entry in `spaces.json` already moves with the folder.
