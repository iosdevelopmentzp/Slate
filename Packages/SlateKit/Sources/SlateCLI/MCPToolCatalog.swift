import Foundation
import MCP

enum MCPToolCatalog {
    static let tools: [Tool] = [
        tool("list_folders", "List the folders of the notes folder with the number of notes in each. writable says if agents may change notes there.", [:], required: [], readOnly: true),
        tool("list_notes", "List notes, newest first: id, title, folder, path, updated, pinned, the start of the text, and type, status and ticket for task notes. plainFile: true marks a Markdown file without a Slate header, like a copied README or a report kept as a resource.", [
            "folder": text("Only notes in this folder and its sub-folders, like Notes or Work/Clients."),
            "limit": number("At most this many notes. Default 50."),
            "headings": flag("true adds the headings of each note, to tell similar notes apart."),
        ], required: [], readOnly: true),
        tool("search_notes", "Search the titles and the text of the notes, like the search in Slate. Returns the notes with a short part of the matching text, then the other files that match by name or text (kind file: text files and PDFs); read those with read_file.", [
            "query": text("The words to search for."),
            "folder": text("Only notes and files in this folder and its sub-folders."),
            "limit": number("At most this many results. Default 20."),
        ], required: ["query"], readOnly: true),
        tool("read_note", "Read a whole note file: the header and the body. Keep the hash for update_note. To read one part, use read_section.", [
            "id": note,
            "path": text("The path inside the notes folder, like Notes/Groceries.md. id takes a path too."),
        ], required: [], readOnly: true),
        tool("read_section", "Read one section of a note: the text under a heading, up to the next heading of the same or a higher level. Returns the hash of the note.", [
            "id": note,
            "path": text("The path inside the notes folder. id takes a path too."),
            "heading": text("The heading text without the # marks, like Status or Plan. Case does not matter."),
        ], required: ["heading"], readOnly: true),
        tool("list_backlinks", "List the notes that link to a note with [[its name]] or with a Markdown link to its file. Use it before you rename or move a note.", [
            "id": note,
            "path": text("The path inside the notes folder. id takes a path too."),
        ], required: [], readOnly: true),
        tool("create_note", "Make a new note in a folder. Slate writes the header and picks a free file name. A missing folder is made, when agents may write there. A note has no size limit, so a long body can go in one call.", [
            "folder": text("The folder, like Notes or Work/Clients."),
            "title": text("The title of the note."),
            "body": text("The Markdown text of the note, without a header."),
        ], required: ["folder", "title"]),
        tool("append_to_note", "Add text at the end of a note, or at the end of a section when section is given. With position top the text goes first: at the start of the note or right under the heading, for lists that keep the newest entry first. A missing section is made as a ## heading.", [
            "id": note,
            "text": text("The Markdown text to add."),
            "section": text("The heading to add the text under."),
            "position": text("end (default) or top."),
        ], required: ["id", "text"]),
        tool("replace_in_note", "Replace one piece of text in the body of a note, like one table row or [ ] with [x] in one checklist line. old must be in the note exactly once: add more text around it when it is not.", [
            "id": note,
            "old": text("The exact text to replace, copied from read_note or read_section."),
            "new": text("The new text. Empty removes the old text."),
            "expectedHash": text("Optional: the hash from read_note or read_section. When given, the change is refused if the note changed since."),
        ], required: ["id", "old", "new"], destructive: true),
        tool("update_section", "Replace the text of one section of a note and keep its heading and the other sections. A missing section is added at the end as a ## heading.", [
            "id": note,
            "heading": text("The heading text without the # marks."),
            "text": text("The new Markdown text of the section, without the heading."),
            "expectedHash": text("Optional: the hash from read_note or read_section. When given, the change is refused if the note changed since."),
        ], required: ["id", "heading", "text"], destructive: true),
        tool("update_note", "Replace the whole body of a note. Slate keeps the header. Pass the hash from read_note: when the note changed after you read it, the change is refused. For a small change use replace_in_note or update_section.", [
            "id": note,
            "body": text("The new Markdown body, without the header."),
            "expectedHash": text("The hash that read_note returned."),
        ], required: ["id", "body", "expectedHash"], destructive: true),
        tool("batch_edit", "Make several small changes in one call, in one or more notes. Slate checks every operation first: when one fails, nothing is written. Each note is written once, and Slate keeps one version for the whole batch.", [
            "operations": operations("The changes, in order. Each one has tool (replace_in_note, update_section, append_to_note or set_plan_item) and the arguments of that tool: id or task, and expectedHash if you want the check."),
        ], required: ["operations"], destructive: true),
        tool("move_note", "Move a note to another folder. Links to images in the note keep working. A missing folder is made, when agents may write there. A folder that the move leaves empty is removed.", [
            "id": note,
            "folder": text("The folder to move the note to."),
        ], required: ["id", "folder"]),
        tool("rename_note", "Change the title of a note. The file name follows the title, and [[links]] to the note in other notes are changed too. The folder keeps its name.", [
            "id": note,
            "title": text("The new title."),
        ], required: ["id", "title"]),
        tool("trash_note", "Move a note to the Trash of Slate. The owner can restore it for 30 days. Agents may do this only when the owner allows it.", [
            "id": note,
        ], required: ["id"], destructive: true),
        tool("list_trash", "List the notes in the Trash of Slate, newest first: the path they had, the title and when they were moved there. Restore one with restore_note.", [:], required: [], readOnly: true),
        tool("restore_note", "Bring a note back from the Trash of Slate to the folder it came from. When several trashed notes had the path, the newest one comes back.", [
            "path": text("The path the note had, from list_trash, like Notes/Groceries.md."),
        ], required: ["path"]),
        tool("move_folder", "Move or rename a folder with its notes, files and sub-folders. Links to images keep working. Missing parent folders are made. Agents may do this only in folders the owner allows; a top-level folder or a project folder cannot be moved.", [
            "folder": text("The folder to move, like Work/Clients/Old."),
            "to": text("The new path of the folder, like Work/Archive/Old. Only the last part changes for a rename, like Work/Clients/Older."),
        ], required: ["folder", "to"]),
        tool("attach_image", "Add an image to a note: under the line that has the text in after, at the end of a section when section is given, or else at the end of the note. With after, an image under a list item stays inside the list, and the numbers go on after it. Slate copies the image into _attachments. PNG, JPEG, GIF, HEIC or WebP, at most 50 MB.", [
            "id": note,
            "after": text("A piece of text from one line of the note, for example the start of a list item. The image goes under that line, or under its paragraph or list item. The text must be in the note exactly once."),
            "section": text("The heading to add the image under, at the end of the section. Not used when after is given."),
            "base64": text("The image data in base64. Use base64 or path."),
            "path": text("The absolute path of an image file on this Mac."),
            "caption": text("A short text that describes the image."),
        ], required: ["id"]),
        tool("open_in_slate", "Show a note in the Slate app.", [
            "id": note,
        ], required: ["id"], readOnly: true),
        tool("project_context", "Find the Slate project of a code repository and read its tasks: status, ticket, branch, folders, plan progress, and the task of the current branch with every step of its plan. Call it at the start of a session.", [
            "path": text("The working directory of the repository. Default: the directory the server runs in."),
            "project": text("The project name in Slate, when the repository is not linked."),
        ], required: [], readOnly: true),
        tool("start_task", "Start a task in a project: Slate makes a task folder and a task note with Overview, Status, Key facts, Questions, Plan and Log, status active.", [
            "title": text("The task title, like ABC-123 Fix the login crash. A ticket at the start is split off."),
            "folder": text("The folder of the project to make the task folder in, like Features or MyApp/Bugs. Missing folders are made. Default: the project folder."),
            "ticket": text("The ticket, when it is not in the title."),
            "branch": text("The git branch. Default: the current branch of the repository."),
            "project": text("The project name. Default: the project of the working directory."),
            "path": text("The working directory of the repository. Default: the directory the server runs in."),
        ], required: ["title"]),
        tool("set_task_status", "Change the status of a task: todo, active, review, done or dropped.", [
            "task": text("The task: its note id, its folder like MyApp/ABC-123 Fix login, or its ticket."),
            "status": text("todo, active, review, done or dropped."),
        ], required: ["task", "status"]),
        tool("set_plan_item", "Mark a step of the Plan of a task note done or not done. The Plan is a checklist: - [ ] 1. The step. Returns the plan with every step.", [
            "task": text("The task: its note id, its folder, or its ticket."),
            "item": text("The step number, like 2, or a part of its text that matches one step."),
            "done": flag("true (default) marks the step done, false marks it open again."),
        ], required: ["task", "item"]),
        tool("log_progress", "Add a dated entry to the Log section of a task note: one line of what was done, with commit hashes. What is left and the next step go into the Status section. Returns the entry as written.", [
            "task": text("The task: its note id, its folder, or its ticket."),
            "text": text("The Markdown text of the entry."),
        ], required: ["task", "text"]),
        tool("add_file", "Copy a file into a folder of the notes folder, like a log, a screenshot, a PDF or JSON. A name with / puts the file into sub-folders, like Resources/run.log. Missing folders are made, when agents may write there. A taken name gets a number. At most 200 MB.", [
            "folder": text("The folder, like MyApp/ABC-123 Fix login."),
            "path": text("The absolute path of the file on this Mac. Use path or base64."),
            "base64": text("The file data in base64. Needs name."),
            "name": text("The file name in Slate, like crash.log, or a path below folder, like Resources/Runs/crash.log."),
        ], required: ["folder"]),
        tool("list_files", "List the files of a folder that are not notes: name, path, size, date. Read one with read_file.", [
            "folder": text("The folder, like MyApp/ABC-123 Fix login."),
        ], required: ["folder"], readOnly: true),
        tool("read_file", "Read a file of a folder that is not a note. A text file (code, log, JSON, plain text) returns its whole text and a hash for update_file and replace_in_file. A PDF returns its text, read only. Other files return only name, size and date.", [
            "path": text("The path inside the notes folder from list_files or search_notes, like MyApp/ABC-123 Fix login/crash.log."),
        ], required: ["path"], readOnly: true),
        tool("replace_in_file", "Replace one piece of text in a text file that is not a note. old must be in the file exactly once: add more text around it when it is not.", [
            "path": text("The path inside the notes folder."),
            "old": text("The exact text to replace, copied from read_file."),
            "new": text("The new text. Empty removes the old text."),
            "expectedHash": text("Optional: the hash from read_file. When given, the change is refused if the file changed since."),
        ], required: ["path", "old", "new"], destructive: true),
        tool("update_file", "Replace the whole text of a text file that is not a note. Pass the hash from read_file: when the file changed after you read it, the change is refused. For a small change use replace_in_file.", [
            "path": text("The path inside the notes folder."),
            "text": text("The new text of the file."),
            "expectedHash": text("The hash that read_file returned."),
        ], required: ["path", "text", "expectedHash"], destructive: true),
        tool("trash_file", "Move a file that is not a note to the macOS Trash. Agents may do this only when the owner allows them to move notes to the Trash.", [
            "path": text("The path inside the notes folder, from list_files."),
        ], required: ["path"], destructive: true),
        tool("save_version", "Save a named version of the notes folder, like a checkpoint at the end of a session. The owner sees it in the versions of each note.", [
            "name": text("A short name, like end of session 3."),
        ], required: ["name"]),
    ]

    private static func tool(_ name: String, _ description: String, _ properties: [String: Value], required: [String], readOnly: Bool = false, destructive: Bool = false) -> Tool {
        Tool(
            name: name,
            description: description,
            inputSchema: [
                "type": "object",
                "properties": .object(properties),
                "required": .array(required.map { .string($0) }),
                "additionalProperties": false,
            ],
            annotations: Tool.Annotations(readOnlyHint: readOnly, destructiveHint: destructive, openWorldHint: false)
        )
    }

    private static let note = text("The note: its id, its path like Notes/Groceries.md (an absolute path works too), its slate:// link, or its exact title.")

    private static func text(_ description: String) -> Value {
        ["type": "string", "description": .string(description)]
    }

    private static func flag(_ description: String) -> Value {
        ["type": "boolean", "description": .string(description)]
    }

    private static func operations(_ description: String) -> Value {
        [
            "type": "array",
            "description": .string(description),
            "items": [
                "type": "object",
                "properties": [
                    "tool": ["type": "string", "enum": ["replace_in_note", "update_section", "append_to_note", "set_plan_item"]],
                    "id": ["type": "string"],
                    "task": ["type": "string"],
                    "old": ["type": "string"],
                    "new": ["type": "string"],
                    "heading": ["type": "string"],
                    "text": ["type": "string"],
                    "section": ["type": "string"],
                    "position": ["type": "string"],
                    "item": ["type": "string"],
                    "done": ["type": "boolean"],
                    "expectedHash": ["type": "string"],
                ],
                "required": ["tool"],
                "additionalProperties": false,
            ],
        ]
    }

    private static func number(_ description: String) -> Value {
        ["type": "integer", "description": .string(description)]
    }
}
