# ADR 0020: Read, change and search the files of a folder

Status: accepted, 2026-10-28. Amends ADR 0014 (files in a folder) and `STORAGE-FORMAT.md` section 9.

## Context

Since ADR 0014 a folder lists its other files, like `crash.log`, `App.swift` or `spec.pdf`, under the notes. The owner and agents add them with a drag from Finder or with `add_file`. Slate showed them only as rows: a double click opened Quick Look in its own window, and Open started another app. To read a file next to the notes, or to fix one line in a text file, the owner had to leave Slate. Search found only notes.

## Decision

1. A click on a file row selects the file. The right column then shows the file instead of a note. A note and a file are never selected at the same time. A double click still opens Quick Look.
2. A file is text when its name has no document, media or archive extension (`FileKindPolicy`), it is at most 4 MB, it has no zero byte in its first 8 KB and it is valid UTF-8. A text file opens in a plain text editor: one monospaced font, no format bar, no Markdown, saved 0.6 s after the last key as UTF-8, byte for byte what was typed. Find works with `⌘F`. A byte order mark is dropped on save.
3. Every other file shows as a Quick Look preview inside the column (`QLPreviewView`): PDF, images, Office and iWork files, HTML, audio and video. Quick Look shows a big icon and the name for a type it cannot read. The preview cannot change the file; Open starts its app.
4. A change on disk reloads a text file that has no unsaved edit. With an unsaved edit the column shows "Changed on disk" with Keep mine and Take theirs, as for a note.
5. Search finds text files and PDF files by their content and by their name, after the notes. The index keeps them in its own tables (`files`, `files_fts`), so the note tables and their queries do not change. At most the first 1 MB of text of a file is indexed. Files in `_attachments/`, `.slate/` and `.trash/` are not indexed.

## Consequences

- `.md` files stay notes and never open in the plain text editor.
- Formatting, tables, images and links exist only in notes. A text file is plain text, without colours for code.
- The search index schema version goes up, so the index is rebuilt once after the update.
- A file over 4 MB or with another encoding than UTF-8 shows only as a preview.
- `search_notes` of `slate mcp` still finds only notes. Agents read files with their own tools.
