---
name: update-docs
description: "End-of-session documentation pass for Slate: add CHANGELOG.md entries under [Unreleased], refresh docs/STATUS.md, keep docs/ARCHITECTURE.md, the rules in .claude/rules (including testing.md) and the skills equal to the code, check that new logic has tests, sync CLAUDE.md tables. Run before finishing any session that changed files, and when the Stop hook asks for it."
---
> Copied from DevHub at bootstrap. Examples still name DevHub features (worktrees, simulators, git commands). Read them as patterns; the Slate types are in `docs/ARCHITECTURE.md`. Update this file when the thing it describes changes in Slate.


# Update Docs

Keeps history and current state readable for the next session. Seven checks, in this order.

## 1. See what changed

```sh
git status --short
git diff --stat HEAD
```

## 2. `CHANGELOG.md`

Add lines under `## [Unreleased]`, grouped as `### Added`, `### Changed`, `### Fixed`, `### Removed`, `### Infrastructure`.

- One line per user-visible change. Describe behaviour, not files: "Worktrees: prune button disables when nothing is missing", not "edited WorktreesView.swift".
- Infrastructure (scripts, hooks, skills, docs) goes under `### Infrastructure`.
- Do not create a version section. Releases are cut on request only (see step 7).

## 3. `docs/STATUS.md`

Update only the parts that moved:

- `Last updated` date.
- `Stage` if something became real or the goal changed.
- `Screens` table for a new screen or a state change.
- `What is mock and what would make it real` when a row turned real: move the real source into the "today" column or delete the row.
- `Decisions` when a new choice was made that a future session must not undo. One numbered line: what, then why.
- `Next steps`: remove finished items, add new ones.
- `Known gaps and ideas`: remove fixed gaps, add new ones found during the session.

## 4. `docs/ARCHITECTURE.md` and `.claude/rules/`

- A new module, folder, port, factory or shared object goes into the module table (section 1), the folder map
  (section 2) or the composition table (section 7) of `docs/ARCHITECTURE.md`.
- A new rule for stores, views, use cases or repositories goes into the matching section there and into the short
  form in `.claude/rules/domain.md`, `data.md`, `presentation.md` or `testing.md`.
- A new test convention, a new spy or a new helper in `SlateTestSupport` goes into section 8 and into
  `.claude/rules/testing.md`.
- A new lookup protocol, event case or `AppActions` method is listed where its siblings are listed.
- When `Scripts/check-layers.sh` needed a new exception, `Scripts/layer-exceptions.txt` has the reason.

## 5. `CLAUDE.md` and skills

- `Layout` table in `CLAUDE.md` when a folder or a key file was added.
- `Conventions` when a new pattern was established and should be reused.
- `/ui-components` when a shared component, formatter or `Tint` case was added or its signature changed.
- `/add-feature` when the way to add a model, port, store, row model or screen changed.
- `/add-use-case` when the policy, use case, lookup or event pattern changed.
- `/data-layer` when `ShellRunner`, a runner, a parser rule, `Ports.live` or the mocks changed.
- `/testing` when a spy, `StoreHarness`, a test helper, a test convention or the test commands changed.
- `/xcode-toolchain` and `/panel-window` when a verified command, trap or window rule changed.
- `/build-and-run` when a script, the layer check, a build setting or `Package.swift` changed.

## 6. Tests

- New logic has a test: a policy, use case, parser, mapper or store action without a suite is a gap.
- A test that pins wrong behaviour on purpose is listed in `docs/STATUS.md` (next steps 0b or known gaps).
- `Scripts/test.sh` prints one passing line.

## 7. Release (only when asked)

1. Rename `## [Unreleased]` to `## [x.y.z] - YYYY-MM-DD` and add a fresh empty `## [Unreleased]` above it.
2. Set `MARKETING_VERSION` in `Slate.xcodeproj/project.pbxproj` to the same version (two occurrences, Debug and Release).
3. Mention the version in the commit message.

## Done when

- `git diff CHANGELOG.md` shows the new lines.
- `docs/STATUS.md` says today's date.
- Nothing in `CLAUDE.md`, `docs/ARCHITECTURE.md` or `.claude/rules/` contradicts the code.
- `Scripts/build.sh` prints `layers: ok` and the app path.
- `Scripts/test.sh` passes.
