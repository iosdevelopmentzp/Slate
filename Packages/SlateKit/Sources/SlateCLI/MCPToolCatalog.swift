import Foundation
import MCP

enum MCPToolCatalog {
    static let tools: [Tool] = [
        tool("list_folders", "List the folders of the notes folder with the number of notes in each. writable says if agents may change notes there.", [:], required: [], readOnly: true),
        tool("list_notes", "List notes, newest first: id, title, folder, path, updated, pinned, the start of the text, and type, status and ticket for task notes.", [
            "folder": text("Only notes in this folder and its sub-folders, like Notes or Work/Clients."),
            "limit": number("At most this many notes. Default 50."),
            "headings": flag("true adds the headings of each note, to tell similar notes apart."),
        ], required: [], readOnly: true),
        tool("search_notes", "Search the titles and the text of the notes, like the search in Slate. Returns the notes with a short part of the matching text.", [
            "query": text("The words to search for."),
            "folder": text("Only notes in this folder and its sub-folders."),
            "limit": number("At most this many results. Default 20."),
        ], required: ["query"], readOnly: true),
        tool("read_note", "Read a whole note file: the header and the body. Keep the hash for update_note. To read one part, use read_section.", [
            "id": text("The note id from list_notes or search_notes."),
            "path": text("The path inside the notes folder, like Notes/Groceries.md. Use id or path."),
        ], required: [], readOnly: true),
        tool("read_section", "Read one section of a note: the text under a heading, up to the next heading of the same or a higher level. Returns the hash of the note.", [
            "id": text("The note id."),
            "path": text("The path inside the notes folder. Use id or path."),
            "heading": text("The heading text without the # marks, like Status or Plan. Case does not matter."),
        ], required: ["heading"], readOnly: true),
        tool("list_backlinks", "List the notes that link to a note with [[its name]] or with a Markdown link to its file. Use it before you rename or move a note.", [
            "id": text("The note id."),
            "path": text("The path inside the notes folder. Use id or path."),
        ], required: [], readOnly: true),
        tool("create_note", "Make a new note in a folder. Slate writes the header and picks a free file name. A missing folder is made, when agents may write there.", [
            "folder": text("The folder, like Notes or Work/Clients."),
            "title": text("The title of the note."),
            "body": text("The Markdown text of the note, without a header."),
        ], required: ["folder", "title"]),
        tool("append_to_note", "Add text at the end of a note, or at the end of a section when section is given. With position top the text goes first: at the start of the note or right under the heading, for lists that keep the newest entry first. A missing section is made as a ## heading.", [
            "id": text("The note id."),
            "text": text("The Markdown text to add."),
            "section": text("The heading to add the text under."),
            "position": text("end (default) or top."),
        ], required: ["id", "text"]),
        tool("replace_in_note", "Replace one piece of text in the body of a note, like one table row or [ ] with [x] in one checklist line. old must be in the note exactly once: add more text around it when it is not.", [
            "id": text("The note id."),
            "old": text("The exact text to replace, copied from read_note or read_section."),
            "new": text("The new text. Empty removes the old text."),
            "expectedHash": text("Optional: the hash from read_note or read_section. When given, the change is refused if the note changed since."),
        ], required: ["id", "old", "new"], destructive: true),
        tool("update_section", "Replace the text of one section of a note and keep its heading and the other sections. A missing section is added at the end as a ## heading.", [
            "id": text("The note id."),
            "heading": text("The heading text without the # marks."),
            "text": text("The new Markdown text of the section, without the heading."),
            "expectedHash": text("Optional: the hash from read_note or read_section. When given, the change is refused if the note changed since."),
        ], required: ["id", "heading", "text"], destructive: true),
        tool("update_note", "Replace the whole body of a note. Slate keeps the header. Pass the hash from read_note: when the note changed after you read it, the change is refused. For a small change use replace_in_note or update_section.", [
            "id": text("The note id."),
            "body": text("The new Markdown body, without the header."),
            "expectedHash": text("The hash that read_note returned."),
        ], required: ["id", "body", "expectedHash"], destructive: true),
        tool("batch_edit", "Make several small changes in one call, in one or more notes. Slate checks every operation first: when one fails, nothing is written. Each note is written once, and Slate keeps one version for the whole batch.", [
            "operations": operations("The changes, in order. Each one has tool (replace_in_note, update_section, append_to_note or set_plan_item) and the arguments of that tool: id or task, and expectedHash if you want the check."),
        ], required: ["operations"], destructive: true),
        tool("move_note", "Move a note to another folder. Links to images in the note keep working.", [
            "id": text("The note id."),
            "folder": text("The folder to move the note to."),
        ], required: ["id", "folder"]),
        tool("trash_note", "Move a note to the Trash of Slate. The owner can restore it for 30 days. Agents may do this only when the owner allows it.", [
            "id": text("The note id."),
        ], required: ["id"], destructive: true),
        tool("attach_image", "Add an image at the end of a note, or at the end of a section when section is given. Slate copies the image into _attachments. PNG, JPEG, GIF, HEIC or WebP, at most 50 MB.", [
            "id": text("The note id."),
            "section": text("The heading to add the image under."),
            "base64": text("The image data in base64. Use base64 or path."),
            "path": text("The absolute path of an image file on this Mac."),
            "caption": text("A short text that describes the image."),
        ], required: ["id"]),
        tool("open_in_slate", "Show a note in the Slate app.", [
            "id": text("The note id."),
        ], required: ["id"], readOnly: true),
        tool("project_context", "Find the Slate project of a code repository and read its tasks: status, ticket, branch, folders, plan progress, and the task of the current branch with every step of its plan. Call it at the start of a session.", [
            "path": text("The working directory of the repository. Default: the directory the server runs in."),
            "project": text("The project name in Slate, when the repository is not linked."),
        ], required: [], readOnly: true),
        tool("start_task", "Start a task in a project: Slate makes a task folder and a task note with Context, Plan, Findings, Links, Questions and Log, status active.", [
            "title": text("The task title, like ABC-123 Fix the login crash. A ticket at the start is split off."),
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
        tool("log_progress", "Add a dated entry to the Log section of a task note: what was done, what is left, the next step. Returns the entry as written.", [
            "task": text("The task: its note id, its folder, or its ticket."),
            "text": text("The Markdown text of the entry."),
        ], required: ["task", "text"]),
        tool("add_file", "Copy a file into a folder of the notes folder, like a log, a screenshot, a PDF or JSON. A taken name gets a number. At most 200 MB.", [
            "folder": text("The folder, like MyApp/ABC-123 Fix login."),
            "path": text("The absolute path of the file on this Mac. Use path or base64."),
            "base64": text("The file data in base64. Needs name."),
            "name": text("The file name in Slate, like crash.log."),
        ], required: ["folder"]),
        tool("list_files", "List the files of a folder that are not notes: name, path, size, date.", [
            "folder": text("The folder, like MyApp/ABC-123 Fix login."),
        ], required: ["folder"], readOnly: true),
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
            ],
            annotations: Tool.Annotations(readOnlyHint: readOnly, destructiveHint: destructive, openWorldHint: false)
        )
    }

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
            ],
        ]
    }

    private static func number(_ description: String) -> Value {
        ["type": "integer", "description": .string(description)]
    }
}
