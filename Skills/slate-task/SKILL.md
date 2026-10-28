---
name: slate-task
description: Keep the documentation of a large coding task in Slate through the slate MCP server. Use it only for a story that adds a feature, or a task with many planned changes or several sessions, or when the task already has a Slate note ("continue the task", "where did we stop"). Do not use it for a bug fix or a small improvement in a few lines or files. Use it after a commit and at the end of a session ("wrap up", "done for today") of such a large task.
---

# Task documentation in Slate

Slate is the owner's notes app. A code repository can be linked to a Slate project. Each task of the project has a folder with a task note: a header with `ticket`, `branch` and `status`, and the sections Context, Plan, Findings, Links, Questions and Log. The next session reads this note and continues from it. The owner reads it in the app.

Use this skill only for a large task: a story that adds a feature, or a task with many planned changes or several sessions of work. Skip it for a small task: a bug fix, a small improvement, or a change in a few lines or files. For a small task the session itself is the record. If the size is not clear at the start, start without Slate, and ask the user before you start a Slate task when the task grows. When the user asks for another documentation mode, or the repository's own rules define one, follow that instead.

Write to Slate only through the `slate` MCP tools, never with file tools. The tools keep the header and the file names correct, and Slate saves a version before and after each change.

## 1. Start of a session

1. Call `project_context` with `path` set to the repository root.
2. If no project is found, the answer lists the known projects. Ask the owner which one it is, then pass it as `project`. To link the repository for the next sessions, the owner uses Link Repository… on the project in Slate. Do not create a project yourself.
3. Find the task, in this order:
   1. the task of the current branch from `project_context`;
   2. the task with the ticket the user named;
   3. no task yet: call `start_task` with a title like `ABC-123 Fix the login crash`. Take the ticket from the user's message or the branch name. Ask the user when neither has one. To make the task folder in a folder of the project, like `Features`, pass it as `folder`.
4. `project_context` shows the plan of the current task: how many steps are done and the next one. Read the task note once with `read_note`: the Plan, the Questions and the last two or three Log entries. Later in the session read one part with `read_section`.
5. Tell the user in two or three lines where the last session stopped and what the next step is.
6. If the status is `todo` and work starts now, call `set_task_status` with `active`.

## 2. During the session

Add text with `append_to_note` and its `section`. For a list that keeps the newest entry first, pass `position: top`. Change text that is already there with the smallest tool:

- `replace_in_note`: one line or one table row, like `- [ ] 2. Tests` to `- [x] 2. Tests`. Copy `old` exactly from the note. When it is in the note more than once, add more of the text around it.
- `update_section`: the whole text under one heading, like Status or Plan.
- `set_plan_item`: mark a step of the Plan done, by its number or a part of its text.
- `batch_edit`: several of the changes above in one call. When one fails, nothing is written.
- `update_note`: only when most of the note changes. Pass the hash from `read_note`.

| Section | What goes there |
|---|---|
| Context | the ticket link, the MR link, what the task is, limits that the owner gave. Write it once at the start |
| Plan | numbered checklist steps (`- [ ] 1. …`). Mark a step done with `set_plan_item`; change the plan with `update_section` |
| Findings | one bullet per fact: a cause, a measured number, a place in code as `path/File.swift:42` |
| Links | MRs, docs, other tickets |
| Questions | open questions to the owner or a team. When one is answered, remove it and write the answer in Findings |
| Log | written only with `log_progress` |

- After each commit, call `log_progress`: the short hash and what the commit did, in one line.
- Save logs, screenshots, crash reports and JSON with `add_file` and its `path`, into the task folder (`MyApp/ABC-123 Fix the login crash`). Give each file a clear name. Do not paste long logs or code into the note.
- A large topic, like a design decision, can get its own note in the task folder with `create_note`. `create_note` also makes a sub-folder that does not exist yet.
- Before you rename or move a note, check `list_backlinks`.
- Never write secrets, tokens or passwords into Slate.

## 3. End of a session

1. Call `log_progress` with three to six lines:
   - **Done:** what changed, with commit hashes.
   - **Left:** what is not done.
   - **Next:** the first step for the next session.
2. Call `set_task_status`:
   - `review` when an MR is open;
   - `done` when the task is finished or merged;
   - `dropped` only when the owner says so;
   - otherwise keep `active`.
3. Call `save_version` with a name like `ABC-123 end of session`.

## Keep it small

The next session reads the whole note, so every line costs tokens later.

- Write facts, not a story. One line per Log entry after a commit.
- Read the task note once per session. Do not read it again after your own writes.
- When the Log has more than about 20 entries, or the task is done, replace the old entries with a short summary: `read_section` with `Log`, then `update_section`.

## Language

Write in plain English: short sentences, common words, no idioms. Keep code names, paths and error text exact.
