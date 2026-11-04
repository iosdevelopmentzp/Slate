# ADR 0021: Task note sections for the owner

Status: accepted, 2026-11-04. Amends `STORAGE-FORMAT.md`, the built-in `task.md` template.

## Context

The built-in task note had the sections Context, Plan, Findings, Links, Questions and Log. Agents filled them and then added more notes for the owner: an overview, a questions note, a readiness table. One task folder had three notes for the owner to read, with the same facts in several places. The owner had to read all of them to learn where the work was and what to answer. The Log also repeated what was left and the next step in every entry.

## Decision

1. The task note is the one page the owner reads. Its built-in sections, in this order:
   1. **Overview**: what the task is in two or three sentences, then a table of links (tickets, MRs, threads, designs, code, branch, the research notes).
   2. **Status**: the state, what blocks, the next step. Agents rewrite it each session; it is not a list of entries.
   3. **Key facts**: only what the reader must know to act. The proof and the sources go into other notes.
   4. **Questions**: Q1, Q2 … with an `Answer:` line, decisions at the end.
   5. **Plan**: the checklist, as before.
   6. **Log**: one line per session or commit. What is left and the next step go into Status.
2. Research, places in code and long results go into more notes in the task folder, for example in `Details/`. A second note for the owner is made only when there is a result to review, such as a breakdown.

## Consequences

- New task notes start with the new sections. Existing task notes keep their sections; Plan and Log keep their names, so `set_plan_item`, `log_progress` and `project_context` work on both.
- A `_templates/task.md` in the notes folder still wins over the built-in body. An owner who wants the new sections replaces that file.
- `slate append --section Findings` on a new task note adds a Findings section at the end, as for any missing section.
