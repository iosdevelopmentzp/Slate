import Foundation

package enum AgentGuide {
    package static let begin = "<!-- slate:begin -->"
    package static let end = "<!-- slate:end -->"
    package static let fileNames = ["CLAUDE.md", "AGENTS.md"]
    package static let registration = "claude mcp add slate -- slate mcp"

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

    Headings `#`, `##`, `###`; paragraphs separated by one blank line; `- item` lists, `1. item` lists and `- [ ] item` checklists, nested by two spaces; `> quote`; fenced code blocks; `---` dividers; `**bold**`, `*italic*`, `~~strikethrough~~`, `` `code` ``; `[text](url)` links and `[[Note name]]` links to other notes; `![](../_attachments/file.png)` images on their own line; GitHub pipe tables. Other Markdown stays in the file as it is, but the app shows it as plain text.

    ## Rules

    1. Use the Slate tools (MCP below) or the `slate` command when you can. They write the header, the file name and the search index for you.
    2. Keep the header of every note.
    3. Never write into `.slate/` or `.trash/`.
    4. Put images into `_attachments/` with the name `yyyyMMdd-HHmmss-<source>.<ext>`, and link them with a path relative to the note: `../_attachments/<file>` from `Folder/Note.md`.
    5. Write a whole file in one operation. Do not write a file line by line.
    6. Do not delete files. Do not change files outside this folder. Do not store passwords, tokens or other secrets in notes.

    ## The slate command

    Every command takes `--json` for JSON output and `--vault <folder>` for another notes folder.

    - `slate new "Groceries" --space Notes --body "Milk"`: make a note and print its path.
    - `slate append "Eggs" --path "Notes/Groceries.md" --section "To buy"`: add text to a note, under a heading.
    - `slate search "milk"`: search titles and text.
    - `slate list --space Notes`: list the notes, newest first.
    - `slate path --title "Groceries"`: print the file path of a note.
    - `slate open --title "Groceries"`: show a note in Slate. The link `slate://open?id=<id>` does the same.

    ## MCP server

    `slate mcp` is an MCP server over stdio. Add it to Claude Code with `\(registration)`. Its tools: `list_folders`, `list_notes`, `search_notes`, `read_note`, `create_note`, `append_to_note`, `update_note`, `move_note`, `trash_note`, `attach_image`, `open_in_slate`. The resource `slate://note/<id>` gives the text of a note.

    The owner chooses in Slate which folders agents may change, and whether agents may create notes or move notes to the Trash. A tool that is not allowed answers with a sentence that says so. Slate keeps a version of the note before every change by an agent.

    """
}
