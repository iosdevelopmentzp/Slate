# ADR 0022: Callouts and questions for agents

Status: accepted, 2026-11-07. Amends `STORAGE-FORMAT.md` section 11.

## Context

Agents write callouts (`> [!NOTE]`, `> [!WARNING]`) in task notes, as GitHub and Obsidian show them. Slate showed them as a grey quote with the `[!NOTE]` mark as text. The owner also wanted a way to ask an agent a question inside a note and get the answer in the same place, without the chat.

## Decision

1. A quote whose first line starts with `[!KIND]` is a callout. The editor shows a tinted block with a bar, an icon and a title line in the colour of the kind. The title is the text after the marker; when there is none, the kind name shows in its place (not as text). The rest of the quote is the body. The kind word is kept as written, with its case and a `+` or `-` fold mark. Unknown kinds look like Note.
2. The file keeps the GitHub form: `> [!KIND] Title` on the first line, the body on the next `> ` lines, paragraphs separated by `>`. A marker alone on its line followed by a blank `>` line is written back without that blank line; both forms mean the same.
3. Format → Callout makes a callout of Note, Tip, Important, Warning or Question from the selected paragraphs, or changes the kind of the callout under the caret.
4. `> [!QUESTION]` is an open question for agents. `list_questions` (MCP) lists the open questions of a note or a folder, numbered per note. `answer_question` writes `**Answer:** …` into the callout under the question and changes the marker to `[!ANSWER]`. The answer stays next to the question, and the question is closed.
5. Copy for Jira turns a callout into a panel macro (`{info}`, `{tip}`, `{note}`, `{warning}`); Copy for Slack into a quote with the title in bold.

## Consequences

- No new file format: the files are plain GitHub and Obsidian callouts, and other tools show them.
- `[!ANSWER]` is not a GitHub kind. GitHub shows such a callout as a plain quote, Obsidian as a note.
- An empty callout (no title, no text) is not written.
