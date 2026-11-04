---
name: slate-task
description: Keep the documentation of a large coding task in Slate through the slate MCP server. Use it only for a story that adds a feature, an internal tooling initiative (an AI skill, a script, a developer process with experiment runs), or a task with many planned changes or several sessions, or when the task already has a Slate note ("continue the task", "where did we stop"). Do not use it for a bug fix or a small improvement in a few lines or files. Use it after a commit and at the end of a session ("wrap up", "done for today") of such a large task.
---

# Task documentation in Slate

Slate is the owner's notes app. A code repository can be linked to a Slate project. Each task of the project has a folder with a task note: a header with `ticket`, `branch` and `status`, and the sections Overview, Status, Key facts, Questions, Plan and Log. The task note is the one page the owner reads in the app. The next session reads it too and continues from it.

Use this skill only for a large task: a story that adds a feature, an internal tooling initiative, or a task with many planned changes or several sessions of work. Skip it for a small task: a bug fix, a small improvement, or a change in a few lines or files. For a small task the session itself is the record. If the size is not clear at the start, start without Slate, and ask the user before you start a Slate task when the task grows. When the user asks for another documentation mode, or the repository's own rules define one, follow that instead.

Write to Slate only through the `slate` MCP tools, never with file tools. The tools keep the header and the file names correct, and Slate saves a version before and after each change.

## 1. Start of a session

1. Call `project_context` with `path` set to the repository root.
2. If no project is found, the answer lists the known projects. Ask the owner which one it is, then pass it as `project`. To link the repository for the next sessions, the owner uses Link Repository… on the project in Slate. Do not create a project yourself.
3. Find the task, in this order:
   1. the task of the current branch from `project_context`;
   2. the task with the ticket the user named;
   3. no task yet: call `start_task` with a title like `ABC-123 Fix the login crash`. Take the ticket from the user's message or the branch name. Ask the user when neither has one. To make the task folder in a folder of the project, like `Features`, pass it as `folder`.
4. `project_context` shows the plan of the current task: how many steps are done and the next one. Read the task note once with `read_note`: Status, Questions (the owner writes answers on the `Answer:` lines), Plan and the last two or three Log entries. Later in the session read one part with `read_section`.
5. Tell the user in two or three lines where the last session stopped and what the next step is.
6. If the status is `todo` and work starts now, call `set_task_status` with `active`.

## 2. During the session

Add text with `append_to_note` and its `section`. For a list that keeps the newest entry first, pass `position: top`. Change text that is already there with the smallest tool:

- `replace_in_note`: one line or one table row, like `- [ ] 2. Tests` to `- [x] 2. Tests`. Copy `old` exactly from the note. When it is in the note more than once, add more of the text around it.
- `update_section`: the whole text under one heading, like Status or Plan.
- `set_plan_item`: mark a step of the Plan done, by its number or a part of its text.
- `batch_edit`: several of the changes above in one call. When one fails, nothing is written.
- `update_note`: only when most of the note changes. Pass the hash from `read_note`.

### The task note: one page for the owner

The owner reads only the task note. Write it so a developer understands the task in one minute: short, plain, no repeated facts. Proof, sources and places in code go into `Details/` (see below), not here.

| Section | What goes there |
|---|---|
| Overview | 2–3 sentences: what the task is and what this work must produce. Then a two-column table of references, one row per kind: Jira, Backend, Design, Discussion (Slack), Data, Code (the main types or files), Branch / MR, Research (`[[links]]` to the `Details/` notes). Leave out a row that has nothing. Update it when a new link or branch appears |
| Status | Rewritten each session with `update_section`, never appended. First line: a marker and the state in bold (`🔴 **Blocked by Q4 and Q5.**`, `🟡 **In progress.**`, `✅ **Done.**`) and one sentence why. Then `**Next:**` the first step for the next session. `**Cleanup:**` only when something must be undone (a temp branch, test data). Last line: `*Updated <date>.*` |
| Key facts | At most about 7 bullets: only what the reader must know to act. Each starts with a bold label (`**Field:**`, `**Limit:**`, `**Root cause:**`). No source on each line; the sources are in `Details/` |
| Questions | See "Questions" below |
| Plan | numbered checklist steps (`- [ ] 1. …`), one short line each. Mark a step done with `set_plan_item`; change the plan with `update_section` |
| Log | written only with `log_progress`: one line per session or commit, with the short hash. What is left and the next step go into Status, not here |

### Questions

- Each question has a stable ID: Q1, Q2 … A new question gets the next free number. Never renumber: Slack, Jira and other notes refer to the IDs.
- Sort the open questions by importance: 🔴 blocks, then 🟡 needed before done, then ⚪ nice to know. Put the legend line `🔴 blocks · 🟡 needed before done · ⚪ nice to know` at the top of the section.
- One paragraph per question, then an empty `Answer:` line under it:

  ```
  **Q4** 🔴 *Team.* Do we build on `dev` or on the feature branch? *Blocks:* the breakdown.
  Answer:
  ```

  The italic word says who answers (*Owner*, *Team*, *Backend*, *Design*, *QA*, *Analytics*). Keep the question to one or two sentences; the long background goes into `Details/`.
- The owner writes the answers on the `Answer:` lines. At the start of each session read them, move each answered question into `### Decisions` at the end of the section as a dated line, and update Status, Key facts and Plan.

### More notes

- `Details/` in the task folder is for the agent: research, sources with links and dates, places in code as `path/File.swift:42`, experiment runs, payloads. Every fact there has a source. The owner does not need to read it. Link these notes from the Overview table.
- A second note for the owner only when there is a result to review that does not fit the task note, like a proposed breakdown into Jira items. Never split the overview, the questions or the status into their own notes.

- After each commit, call `log_progress`: the short hash and what the commit did, in one line. Update Status when the state or the next step changes.
- Save logs, screenshots, crash reports and JSON with `add_file` and its `path`, into the task folder (`MyApp/ABC-123 Fix the login crash`). Give each file a clear name. Do not paste long logs or code into the note.
- A large topic, like a design decision or an investigation, gets its own note in `Details/` with `create_note`. `create_note` also makes a sub-folder that does not exist yet.
- Before you rename or move a note, check `list_backlinks`.
- Never write secrets, tokens or passwords into Slate.

## 3. End of a session

1. Rewrite Status with `update_section`: the state, what blocks, `**Next:**`, the date.
2. Call `log_progress` with one line: what was done in this session, with commit hashes.
3. Call `set_task_status`:
   - `review` when an MR is open;
   - `done` when the task is finished or merged;
   - `dropped` only when the owner says so;
   - otherwise keep `active`.
4. Call `save_version` with a name like `ABC-123 end of session`.

## Keep it small

The next session reads the whole note, so every line costs tokens later.

- Write facts, not a story. One line per Log entry.
- Say each fact once. When Key facts says it, do not repeat it in Status or the Log.
- Read the task note once per session. Do not read it again after your own writes.
- When the Log has more than about 20 entries, or the task is done, replace the old entries with a short summary: `read_section` with `Log`, then `update_section`.

## Older task notes

A task note made before these sections has Context, Findings and Links. When you work on such a task, move it to the new layout once: Context and Links become Overview, Findings become Key facts (the long part goes to `Details/`), and add Status. Ask the owner first when the note is large.

## Language

Write in plain English: short sentences, common words, no idioms. Keep code names, paths and error text exact.
