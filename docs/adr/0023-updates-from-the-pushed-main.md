# ADR 0023: Updates from the pushed main

Status: accepted, 2026-11-07. Replaces the `post-commit` and `post-merge` hooks that ran `Scripts/auto-install.sh`.

## Context

Slate is built from source on the owner's Mac (ADR 0003). The hooks installed a new build after each commit on `main` in the working copy. That tied updates to one checkout, restarted the app on every local commit, and did nothing when `main` changed elsewhere. The owner wants to run `install.sh` once and have the app offer updates by itself.

## Decision

1. `install.sh` makes a separate clone of the repository's `origin` in `~/Library/Application Support/Slate/source` (once) and writes `~/Library/Application Support/Slate/update/installed.json` with the installed commit, the branch (`main`) and the clone path.
2. The app (`UpdateStore`, every 5 minutes and at launch) fetches `main` in that clone. When the installed commit is an ancestor of `origin/main`, the commits between are new; the sidebar shows "Update available · N changes". An installed commit the remote does not have (a build of unpushed commits) gives no update.
3. Update Now starts `Scripts/update.sh` of the clone detached (`nohup`), so it lives on when the app quits. It resets the clone to `origin/main` and runs `install.sh` from it. Each step goes to `status.json`; the app shows the step and the time since the start. The app is closed only for the copy into `/Applications`, then opened again, and says "Updated to <hash>".
4. A failed step leaves the old app running; the sidebar shows "Update failed" with the end of `update.log` and Try Again.
5. The hooks and `auto-install.sh` are removed.

## Consequences

- Updates come only from the pushed `main`. A local commit is installed by running `install.sh` by hand.
- The build clone keeps its own `DerivedData`, so updates build incrementally.
- The clone is the updater's own: `reset --hard` there never touches the owner's work.
- No percentage is shown: `xcodebuild` reports none.
