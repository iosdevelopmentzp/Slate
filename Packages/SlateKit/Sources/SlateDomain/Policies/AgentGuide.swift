import Foundation

package enum AgentGuide {
    package static let begin = "<!-- slate:begin -->"
    package static let end = "<!-- slate:end -->"
    package static let fileNames = ["CLAUDE.md", "AGENTS.md"]
    package static let registration = "claude mcp add -s user slate -- slate mcp"

    package static var block: String {
        begin + "\n" + text + end + "\n"
    }

    private static let text = """
    # Slate notes folder

    Slate writes the text between the slate:begin and slate:end markers and replaces it when the app changes. Write your own text above or below the markers. Slate never changes it.

    This folder holds notes for Slate, a macOS notes app. Every note is a Markdown file. Other apps and scripts may read and change the notes, if they follow the rules below.

    ## Layout

    - `<Folder>/<Note>.md`: a note. A folder may hold sub-folders, like `Work/Clients/Call notes.md`.
    - `_attachments/`: images and files that notes link to. One flat folder.
    - `<Project>/`: a project, a folder for the documentation of one code repository. `<Project>/<ABC-123 Title>/` is a task folder with its task note `<ABC-123 Title>.md`, more notes and any files.
    - `.slate/`: settings of the app. Do not write here.
    - `.trash/`: deleted notes. Do not write here.
    - `CLAUDE.md`, `AGENTS.md`: this guide. They are not notes.

    ## A note file

    A note starts with a header between two `---` lines, then the body:

    ```
    ---
    id: 9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d
    title: Groceries
    created: 2026-10-16T09:12:33+03:00
    updated: 2026-10-16T10:01:02+03:00
    pinned: false
    ---
    The body in Markdown.
    ```

    - The app owns `id`, `created` and `updated`. Never change `id`. Keep the header when you change a note.
    - `title` is the name in the app. The file name is the title.
    - Keep unknown header keys as they are.

    ## The Markdown that the app writes

    Headings `#`, `##`, `###`; paragraphs separated by one blank line; `- item` lists, `1. item` lists and `- [ ] item` checklists, nested by two spaces; `> quote`; fenced code blocks; `---` dividers; `**bold**`, `*italic*`, `~~strikethrough~~`, `` `code` ``; `[text](url)` links and `[[Note name]]` links to other notes; `![](../_attachments/file.png)` images on their own line; GitHub pipe tables. A list item holds one line of text and its nested items, nothing else: a table, a code block, a quote or a second paragraph indented under an item makes the app show the whole list as plain Markdown, so put them after the list, not inside it. Other Markdown stays in the file as it is, but the app shows it as plain text.

    ## Rules

    1. Use the Slate tools (MCP below) or the `slate` command when you can. They write the header, the file name and the search index for you.
    2. Keep the header of every note.
    3. Never write into `.slate/` or `.trash/`.
    4. Put images into `_attachments/` with the name `yyyyMMdd-HHmmss-<source>.<ext>`, and link them with a path relative to the note: `../_attachments/<file>` from `Folder/Note.md`.
    5. Write a whole file in one operation. Do not write a file line by line.
    6. Do not delete files. Do not change files outside this folder. Do not store passwords, tokens or other secrets in notes.

    ## Projects and tasks

    A project belongs to a code repository. When you work on a task in a repository, keep its documentation in Slate, so the next session can go on where this one stopped:

    1. At the start of a session call `project_context` (MCP) or run `slate project` in the repository. It names the project, its tasks with status, and the task of the current branch.
    2. No task yet: `start_task` with a title like `ABC-123 Fix login`, or `slate task new "ABC-123 Fix login"`. Slate makes the task folder and the task note with Context, Plan, Findings, Links, Questions and Log.
    3. Write what you learn into the task note or into more notes in the task folder. Add logs, screenshots, JSON and other files with `add_file`.
       Change a few lines with `replace_in_note` (one row, `[ ]` to `[x]`) or `update_section` (one section). Read one section with `read_section`. For a list that keeps the newest entry first, use `append_to_note` with `position: top`. Several changes at once go in one `batch_edit`.
       Keep the Plan as a checklist (`- [ ] 1. The step`) and mark a step done with `set_plan_item`. `project_context` shows how many steps are done.
    4. At the end of a session call `log_progress` (or `slate task log ABC-123 "…"`): what was done, what is left, the next step.
    5. Set the status with `set_task_status` (or `slate task status ABC-123 review`): `todo`, `active`, `review`, `done`, `dropped`.

    The header of a task note has `type: task`, `ticket`, `branch` and `status`. Keep them.

    ## The slate command

    Every command takes `--json` for JSON output and `--vault <folder>` for another notes folder.

    - `slate new "Groceries" --space Notes --body "Milk"`: make a note and print its path.
    - `slate append "Eggs" --path "Notes/Groceries.md" --section "To buy"`: add text to a note, under a heading.
    - `slate search "milk"`: search titles and text.
    - `slate list --space Notes`: list the notes, newest first.
    - `slate path --title "Groceries"`: print the file path of a note.
    - `slate open --title "Groceries"`: show a note in Slate. The link `slate://open?id=<id>` does the same.
    - `slate project`: the project of the current repository and its tasks. `slate project add MyApp --repo .` links a repository to a project.
    - `slate task new "ABC-123 Fix login"`, `slate task status ABC-123 done`, `slate task log ABC-123 "Next: tests"`: work with a task of the current repository.

    ## MCP server

    `slate mcp` is an MCP server over stdio. Add it to Claude Code with `\(registration)`. Its tools: `list_folders`, `list_notes`, `search_notes`, `read_note`, `read_section`, `list_backlinks`, `create_note`, `append_to_note`, `replace_in_note`, `update_section`, `batch_edit`, `update_note`, `move_note`, `trash_note`, `attach_image`, `open_in_slate`, and for projects `project_context`, `start_task`, `set_task_status`, `set_plan_item`, `log_progress`, `add_file`, `list_files`, `save_version`. The resource `slate://note/<id>` gives the text of a note.

    The owner chooses in Slate which folders agents may change, and whether agents may create notes or move notes to the Trash. A tool that is not allowed answers with a sentence that says so. Slate keeps a version of the note before every change by an agent.

    """
}
