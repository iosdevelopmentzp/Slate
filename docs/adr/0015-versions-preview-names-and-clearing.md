# ADR 0015: Versions: preview and diff, versions of files, named versions, a list of changes, clearing

Status: accepted, 2026-10-18. Built in milestone S10. Extends M5 (history through git outside the notes folder, ADR 0002).

## Context

Slate keeps versions of the notes folder in a git repository outside it (`<support>/history.git`). The clock button of a note lists versions with Restore, but the owner cannot see a version before restoring it. Agents now write into projects (ADR 0014), and the owner wants to see what changed and who changed it, to keep versions of other files too, to mark a version by name, and to remove old versions.

## Decision

1. **One history repository.** Projects do not get their own repositories. One repository keeps Restore working for a note that lived in an ordinary folder before the folder became a project, and keeps one backup push. A list of changes of a folder is `git log -- <folder>`.
2. **Preview and diff.** The versions popover of a note lists the versions on the left. A click shows the version on the right, either the changes since that version (lines added and removed against the current text, `LineDiffPolicy` on `CollectionDifference`) or its text. Restore works as before.
3. **Versions of files.** Every file in the notes folder is in the history, not only notes. A file's menu has Versions…: Quick Look of an old version (copied to a temporary file) and Restore (a version of the current file first, then the old bytes). `contents(of:at:)` reads raw bytes, so binary files come back unchanged.
4. **Large files stay out.** Before each snapshot, files larger than 50 MB are written into `info/exclude` of the history repository. The Versions popover of such a file says so.
5. **Named versions.** Save Version with a name makes a snapshot with the message `version: <name>`. Named versions show with their name and a bookmark. Agents call `save_version`. Every agent write already keeps its own version, so `save_version` right after a write often finds nothing new. Then it renames the last version to `version: <name>`, when an agent made that version and Slate has not pushed it to the backup server (amendment, 2026-10-28). Slate stores the last pushed commit in `slate-pushed` in the history repository. With a backup address and no stored push, the last version keeps its message.
6. **Changes of a folder.** The clock button in the list header of a folder shows its last 100 versions, newest first: who made each one (an agent tool in plain words with an Agent badge, a named version, or "Saved by Slate"), and the notes and files added, changed or removed. A click on a note opens it.
7. **Clearing.** Clear History in Settings removes every older version: one new commit holds the current state. Clear History of a folder (in its Changes popover) removes that folder from every older version and keeps the rest. Both ask inline first. The folder case rewrites the history in a temporary bare copy of the repository and then moves the branch, because `git filter-branch` in the repository itself would also remove the folder from the disk. After a clear, the next backup push uses `--force`.

## Consequences

- The storage format does not change: the history lives outside the notes folder.
- Clearing cannot be undone. A backup remote keeps old commits until its host removes unreferenced objects.
- A version list of a file shows dates, not sizes.

## Alternatives rejected

- A repository per project: per-project clearing is simpler, but Restore and the version list of a note would have to read two repositories, and a backup would need one branch per project.
- `git filter-branch` in the real repository: it removes the cleared folder from the disk (tried, the folder was gone).
