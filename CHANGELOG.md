# Changelog

All notable changes to Slate. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Newest first.

Every session that changes code adds lines under **Unreleased** before it ends. One line per user-visible change, described as behaviour, not as files. Scripts, hooks, skills and docs go under **Infrastructure**.

## [Unreleased]

### Added
- The menu bar icon opens a panel with a list of sample notes in two folders, Inbox and Tasks. The panel can be moved and resized and remembers both.
- The folder menu in the header switches between All notes and one folder. The search field (`⌘F`) filters the list by title.
- List rows show the title, the date, a two-line preview, the status, the ticket, the number of images and open checkboxes, and a pin for pinned notes.
- The selected note shows its title and chips above a plain editor. Changes are not saved yet.
- "Open as window" opens a normal window with a sidebar of folders and their note counts. `⌘0` hides the sidebar.
- The app follows the system appearance, light or dark.

### Changed

### Fixed

### Infrastructure
- Specification: `docs/SPEC.md`, `docs/STORAGE-FORMAT.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `docs/PLAYBOOK.md`, `docs/BOOTSTRAP.md`, `docs/UX.md`, six ADRs.
- Xcode project with the settings from `docs/BOOTSTRAP.md` section 1 and the local package `Packages/SlateKit` (nine modules, five test targets, one test each).
- `Scripts/`: `build.sh`, `test.sh`, `run.sh`, `install.sh`, `check-layers.sh`, `layer-exceptions.txt`.
- `.claude/`: session brief and changelog hooks, rules (`layers`, `domain`, `data`, `presentation`, `testing`), seven skills copied from DevHub.
- M0: shared UI blocks, hints and formatters, `AppWindows`, `MenuBarPanel`, `WindowLayout`, drag and resize, `Navigator`, `ActivityLog`, `Toaster`, `AppEvents`, `RefreshTask`, `ActionRunner`, `ShellRunner`, `UserDefaultsKeyValueStore` and test helpers copied from DevHub and cleaned of DevHub features.
- M0: `MockVault`, mock and spy ports for the note list and folders, 48 tests in 19 suites.
- `check-layers.sh`: the `UserDefaults` rule matches the whole word only, so the `UserDefaultsKeyValueStore` type name is allowed.
- `panel-window` skill rewritten for Slate; `ui-components` skill and the rules updated for the removed formatters and the new `Ports.spies(keyValues:)`.
