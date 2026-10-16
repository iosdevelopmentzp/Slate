# ADR 0002: A local folder for the vault, history and backup through git outside the vault

Status: accepted, 2026-10-16. Replaces the earlier draft that proposed iCloud Drive as the default.

## Context

The owner wants a remote backup and a history of changes. There is no Apple Developer account, so CloudKit and an iCloud container are out. The owner chose a local folder over iCloud Drive (decision Q1): simpler, no sync delays, no placeholder files, no conflict versions from a second Mac.

## Decision

- The vault is a local folder chosen on first launch, default `~/Documents/Slate`. Any folder works; a folder inside iCloud Drive or another sync service is allowed but not special in v1 (the sync-specific handling is F3, P2).
- All file access goes through `NSFileCoordinator` with atomic writes, so another tool can edit the same files safely.
- History and backup are git: a repository stored in Application Support, used with `GIT_DIR` and `GIT_WORK_TREE`, so the vault never contains `.git`. A snapshot is taken every ten minutes when something changed and on quit. A private remote is optional and configured in Settings; the app pushes after a snapshot when a remote is set.

## Consequences

- No sync code, no server, no accounts. The remote backup is a git host the owner already uses.
- A second Mac gets the notes by cloning the remote into its own vault; there is no automatic two-way sync in v1. That is an accepted limit.
- Conflicts can still happen when another tool edits a file while it is open in Slate; the editor shows a banner and never overwrites in silence (F2).
- Should a synced folder become the vault later, placeholders and conflict versions need F3; git keeps working because it never writes into the vault.

## Alternatives rejected

- iCloud Drive as the default: works without an entitlement, but brings placeholders, conflict versions and sync delays; the owner did not want them.
- CloudKit: not available.
- Git as the sync channel between Macs (auto pull and push): merge conflicts in Markdown block everything; kept as a manual option.
