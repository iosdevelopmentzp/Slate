# ADR 0011: Sub-folders at any depth

Status: accepted, 2026-10-17. Widens ADR 0007 (v1 scope) and changes `STORAGE-FORMAT.md` section 1.

## Context

v1 had one level of folders. The notes folder always allowed notes at any depth under a top-level folder, but the app created and moved notes only at depth 1 and showed a deeper note in its top-level folder. The owner asked for sub-folders: make them in the app, open them, and keep notes in them.

## Decision

1. **Any depth.** A folder can hold sub-folders, and a sub-folder can hold its own. A sub-folder is a plain folder on disk; its name follows the same rules as a top-level folder name.
2. **A folder shows its own notes and its sub-folders.** The list of a folder shows the sub-folders first, as rows with a count, and then the notes that sit directly in the folder. A click on a sub-folder row opens it. A back button next to the title goes to the parent. "All notes" still lists every note.
3. **The sidebar is a tree.** A folder with sub-folders has an arrow that shows or hides them; the open state is remembered. The count of a folder is the number of notes in it and in all its sub-folders.
4. **Colour, icon and order stay top-level only.** `.slate/spaces.json` does not change. A sub-folder uses the colour of its top-level folder and an outline folder icon, and sub-folders are sorted by name.
5. **Notes go where you are.** A new note in a sub-folder is made there. A note can move to any folder or sub-folder (the card menu and drag and drop).
6. **Links to images follow the note.** When a note moves to another depth, the links into `_attachments/` in its text are rewritten (`../_attachments/a.png` becomes `../../_attachments/a.png`). Other links do not change.
7. **Delete a sub-folder:** the app asks in the sidebar first; every note in it and below it moves to the parent folder; the folder is removed (to the macOS Trash when it still holds other files); a toast offers Undo, which makes the folders again and moves the notes back to their old paths. Deleting a top-level folder works as before.
8. **Rename a sub-folder** renames the folder on disk and reads the index again.

## Consequences

- `STORAGE-FORMAT.md` section 1: the app creates and moves notes at any depth, not only at depth 1. Files written before stay valid; other tools see plain folders.
- The `VaultFileStore` port takes a `FolderPath` for folder operations and lists sub-folders with `folders()`.
- Search in a sub-folder looks in the sub-folder and below it.
- Not in this decision: dragging a folder into another folder, colours or icons per sub-folder, ordering sub-folders by hand.
