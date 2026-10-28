# ADR 0019: Task folders in sub-folders of a project

Status: accepted, 2026-10-28. Amends ADR 0014 section 2 and `STORAGE-FORMAT.md` sections 1 and 7.1.

## Context

ADR 0014 put a task folder directly in a project: `<Project>/<ABC-123 Title>/`. Owners with many tasks sort them into sub-folders, for example `<Project>/Features/` and `<Project>/Bugs/`. Agents did this with `start_task` and then `move_note`. Three problems followed:

1. `start_task` always made the task folder at the project root. After the move, an empty folder stayed there, and no tool could remove it.
2. `move_note` refused a target folder that did not exist yet.
3. The task tools (`project_context`, `log_progress`, `set_task_status`, `set_plan_item`) found a task note only at `<Project>/<Task>/<Task>.md`. A task in `Features/` was invisible to them.

## Decision

1. A task folder can sit at any depth inside a project: `<Project>/<ABC-123 Title>/` or `<Project>/Features/<ABC-123 Title>/`. A task note is a note with `type: task` in the header, in any folder below the project root. A note directly in the project root is never a task.
2. `start_task` takes an optional `folder`: a folder of the project, like `Features` or `MyApp/Bugs`. Slate makes the missing folders and the task folder inside it. A folder outside the project is refused.
3. `move_note` makes a missing target folder, like `create_note` does. When the move leaves the old folder with no notes, files or sub-folders, Slate removes it. A top-level folder is never removed.

## Consequences

- The task tools find a task by its note id, ticket, folder or title at any depth.
- Agents start a task in the right folder with one call. No move is needed.
- Nothing in the files changes. Older task folders at the project root keep working.
