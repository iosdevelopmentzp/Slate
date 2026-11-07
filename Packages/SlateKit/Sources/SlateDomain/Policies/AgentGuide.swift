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

    Headings `#`, `##`, `###`; paragraphs separated by one blank line; `- item` lists, `1. item` lists and `- [ ] item` checklists, nested by two spaces; `> quote`; fenced code blocks; `---` dividers; `**bold**`, `*italic*`, `~~strikethrough~~`, `` `code` ``; `[text](url)` links, plain `https://…` addresses (the app shows them as links) and `[[Note name]]` or `[[Note name|text]]` links to other notes; `![](../_attachments/file.png)` images on their own line, `![photo|420](…)` for an image 420 points wide; GitHub pipe tables, a line break in a cell as `<br>`, images in cells. Code blocks with a language after the three backticks (`swift`, `objc`, `json`, `yaml`, `bash`, `diff`, `log`) get colours. Colours: `==text==` is a yellow highlight; `<mark style="background: #BBFABBA6;">text</mark>` a green one (blue `#ADCCFFA6`, pink `#FFB8EBA6`, purple `#D2B3FFA6`); `<span style="color: #E5484D;">text</span>` red text (orange `#F76B15`, green `#30A46C`, blue `#0090FF`, grey `#8B8D98`). Only these colours show; any other inline HTML shows as plain Markdown. A list item holds one line of text, its nested items and images, nothing else. An image goes under an item after a blank line, indented to the start of the item text (three spaces after `1. `, two after `- `), with a blank line after it; `attach_image` with `after` does this for you. A table, a code block, a quote or a second paragraph indented under an item makes the app show the whole list as plain Markdown, so put them after the list, not inside it. Callouts, as in GitHub and Obsidian: `> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]`, `> [!QUESTION]`, `> [!ANSWER]` on the first line, an optional title after the marker, the text on the next `> ` lines; the app shows a tinted block with an icon and the title. Other Markdown stays in the file as it is, but the app shows it as plain text.

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
    2. No task yet: `start_task` with a title like `ABC-123 Fix login`, or `slate task new "ABC-123 Fix login"`. Slate makes the task folder and the task note with Overview, Status, Key facts, Questions, Plan and Log. To put the task folder in a folder of the project, like `Features`, pass it as `folder`.
    3. Write what you learn into the task note or into more notes in the task folder. Add logs, screenshots, JSON and other files with `add_file`.
       Change a few lines with `replace_in_note` (one row, `[ ]` to `[x]`) or `update_section` (one section). Read one section with `read_section`. For a list that keeps the newest entry first, use `append_to_note` with `position: top`. Several changes at once go in one `batch_edit`.
       Keep the Plan as a checklist (`- [ ] 1. The step`) and mark a step done with `set_plan_item`. `project_context` shows how many steps are done.
    4. At the end of a session rewrite the Status section with `update_section`: the state, what blocks, the next step. Then call `log_progress` (or `slate task log ABC-123 "…"`) with one line of what was done.
    5. Set the status with `set_task_status` (or `slate task status ABC-123 review`): `todo`, `active`, `review`, `done`, `dropped`.

    The header of a task note has `type: task`, `ticket`, `branch` and `status`. Keep them.

    ## Questions from the owner

    The owner asks an agent a question in any note with a callout: `> [!QUESTION]` on the first line, the question on the next `> ` lines. At the start of a session call `list_questions` with the task folder (or a note id). Answer each one with `answer_question` and its number: the answer goes into the callout and the marker becomes `> [!ANSWER]`, so the question is closed. Ask the owner a question the same way: write a `> [!QUESTION]` callout in the task note and say so in the session.

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

    `slate mcp` is an MCP server over stdio. Add it to Claude Code with `\(registration)`. Its tools: `list_folders`, `list_notes`, `search_notes`, `read_note`, `read_section`, `list_backlinks`, `list_questions`, `answer_question`, `create_note`, `append_to_note`, `replace_in_note`, `update_section`, `batch_edit`, `update_note`, `move_note`, `rename_note`, `trash_note`, `list_trash`, `restore_note`, `move_folder`, `attach_image`, `open_in_slate`, and for projects `project_context`, `start_task`, `set_task_status`, `set_plan_item`, `log_progress`, `add_file`, `list_files`, `save_version`, and for other files of a folder `read_file`, `replace_in_file`, `update_file`, `trash_file`. The resource `slate://note/<id>` gives the text of a note. Wherever a tool asks for a note `id`, the note's path (`Notes/Groceries.md` or an absolute path), its `slate://` link or its exact title works too.

    The owner chooses in Slate which folders agents may change, and whether agents may create notes or move notes to the Trash. A tool that is not allowed answers with a sentence that says so. Slate keeps a version of the note before every change by an agent.

    """
}
