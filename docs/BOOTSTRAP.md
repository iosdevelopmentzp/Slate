# Bootstrap: how to start the repository

Two actors: the **owner** (creates the Xcode project, fills the private word list, links the package product) and the **agent** (everything else). Steps marked **owner** need a human in Xcode.

---

## 1. Owner: create the Xcode project (done 2026-10-16)

The owner created the project; the agent applied the settings below, linked the package and removed `ContentView.swift`. Kept as the record of what the project must look like.

In this folder (`Slate/`), which already holds `README.md`, `CLAUDE.md` and `docs/`:

1. `git init` (if not done). Commit the docs.
2. Xcode → File → New → Project → macOS → App. Product name `Slate`. Interface SwiftUI, language Swift. **Uncheck "Include Tests"**. Bundle identifier of your choice with no company name, for example `local.slate.app`. Save into this folder so that `Slate.xcodeproj` and `Slate/` sit next to `docs/`.
3. Build settings on the target `Slate`:

   | Setting | Value | Why |
   |---|---|---|
   | `MACOSX_DEPLOYMENT_TARGET` | the installed SDK (26.4 today) | same as DevHub |
   | `SWIFT_VERSION` | `6.0` | Swift 6 language mode |
   | `SWIFT_DEFAULT_ACTOR_ISOLATION` | `MainActor` | the app host is UI |
   | `SWIFT_APPROACHABLE_CONCURRENCY` | `YES` | |
   | `SWIFT_STRICT_CONCURRENCY` | `complete` | |
   | `ENABLE_APP_SANDBOX` | `NO` | `screencapture`, `git`, `open`, any folder as the vault (ADR 0003) |
   | `ENABLE_HARDENED_RUNTIME` | `NO` | ad-hoc local build |
   | `CODE_SIGN_STYLE` | `Automatic`, Team "None" → "Sign to Run Locally" | no developer account |
   | `INFOPLIST_KEY_LSUIElement` | `YES` | menu bar app, no Dock icon |
   | `GENERATE_INFOPLIST_FILE` | `YES` | switched to a checked-in `Info.plist` at M6 (Services) |
   | `INFOPLIST_KEY_NSHumanReadableCopyright` | empty | anonymity |

4. Target → Info → URL Types → add one: identifier `slate`, URL Schemes `slate`, role Editor. (The agent can also add this later in the checked-in `Info.plist`.)
5. Keep the Xcode synchronized folder `Slate/`. Delete the generated `ContentView.swift`; keep `SlateApp.swift` and `Assets.xcassets`. The agent rewrites `SlateApp.swift` in M0.
6. File → New → Package… → Library, name `SlateKit`, location `Packages/` inside the project folder, "Add to" the `Slate` project. Xcode creates `Packages/SlateKit` with one library target. The agent replaces `Package.swift` with the one in `ARCHITECTURE.md` 1.1 in M0.
7. Open the project once so the `Slate` scheme exists; build once; commit.
8. Done: the local package reference and the `SlateComposition` product dependency are in `project.pbxproj`.

Tools on the machine: Xcode with command line tools, `git`, `python3` (hook scripts). Optional: `brctl` (present on every Mac), `glab` (for G7 later).

## 2. Owner: nothing else

No word list, no account, no certificate. The anonymity rule (ADR 0006) is checked by reading the diff before a commit.

## 3. Agent: copy from the sibling repositories

Done at bootstrap: `Scripts/`, hooks, `settings.json`, the five rules, seven skills (with a note that their examples still name DevHub features), `.gitignore`, `CHANGELOG.md`, `docs/STATUS.md`. Done in M0: every `DevHub/…` Swift source row below (what was left out and why is in `docs/STATUS.md`, decision 12). Still to copy: the `Verba/` rows, each in the milestone that needs it (capture panel and hot keys in M4, Keychain with the Jira token, the rules and skills when their topic is first touched).

Paths are relative to the parent folder of this repository (`../DevHub`, `../Verba`). Copy, rename `DevHub` → `Slate` and `devhub` → `slate`, then remove every feature-specific piece (git, simulators, builds, logs, Slack, Claude sessions, usage). Check the copied text for project names by reading it.

| From | Take | Into |
|---|---|---|
| `DevHub/Scripts/` | `build.sh`, `test.sh`, `check-layers.sh`, `layer-exceptions.txt`, `run.sh`, `install.sh` | `Scripts/` (adjust module names and the extra rules of `ARCHITECTURE.md` section 13; add `generate-vault.sh`) |
| `DevHub/.claude/hooks/`, `DevHub/.claude/settings.json` | session brief on start, changelog check on stop | `.claude/` |
| `DevHub/.claude/rules/` | `layers.md`, `domain.md`, `data.md`, `presentation.md`, `testing.md` | `.claude/rules/` (edit module names and paths) |
| `DevHub/.claude/skills/` | `add-feature`, `add-use-case`, `data-layer`, `testing`, `panel-window`, `build-and-run`, `xcode-toolchain`, `update-docs`, `ui-components` | `.claude/skills/` (remove simulator and build content from `xcode-toolchain`; keep `xcodebuild`, DerivedData, signing, smoke check) |
| `DevHub/docs/generic-hub/seed/` | `CHANGELOG.md`, `docs/STATUS.md` templates, `.gitignore` | repository root and `docs/` |
| `DevHub/Packages/DevHubKit/Sources/DevHubUI/` | every component, `Theme`, `Tint`, `Formatters/`, `Hint/`, `CopyOnClick` | `SlateUI/` |
| `DevHub/…/DevHubPresentation/Shared/` | `Navigator`, `ActivityLog`, `Toaster`, `PasteboardWriter`, `WindowLayout`, `ActionRunner`, `RefreshTask`, `Events/`, `View+Inject`, `View+PreviewEnvironment` | `SlatePresentation/Shared/` |
| `DevHub/…/DevHubPresentation/Shell/` | `AppWindows`, `MenuBarPanel`, `RootView` shape, drag and resize, `HintOverlay` | `SlatePresentation/Shell/` |
| `DevHub/…/DevHubData/Shell/` | `ShellRunner`, `ShellResult`, `LineBatcher`, `CommandFormatter` | `SlateData/Shell/` |
| `DevHub/…/DevHubData/Persistence/` | `UserDefaultsKeyValueStore` | `SlateData/Persistence/` |
| `DevHub/…/DevHubTestSupport/` | `Spy` pattern, `TemporaryDirectory`, `WaitUntil`, `TestError` | `SlateTestSupport/` |
| `Verba/.claude/rules/` | `concurrency.md`, `ui-panel.md` | `.claude/rules/` |
| `Verba/Verba/App/` | `FloatingPanel`, `HotkeyController` (KeyboardShortcuts names) | `SlatePresentation/Shell/CapturePanel`, `SlateComposition/Hotkeys.swift` |
| `Verba/Verba/Data/` | `KeychainSecretStore` | `SlateData/Secrets/` |
| `Verba/.claude/skills/` | `commit`, `run-and-debug` | `.claude/skills/` |
| `Verba/.claude/rules/` | `swift-style.md` | `.claude/rules/swift-style.md` |

Not copied: anything that names a project, a host, a ticket prefix or a person. The global `~/.claude/CLAUDE.md` rules (no comments, plain English) apply on top.

External community skills for Swift or macOS are not needed: the copied skills are specific to this exact architecture. If one is tried later, read it in full first; registries list thousands of unreviewed files.

## 4. Agent: external packages

Done: `GRDB.swift` 7.11.1, `swift-markdown` 0.9.0, `KeyboardShortcuts` 1.10.0, `swift-argument-parser` 1.8.2 are in `Package.swift` and in `docs/STATUS.md`. No other package without an ADR.

## 5. Agent: first files

Done: `CHANGELOG.md`, `docs/STATUS.md`, `.gitignore`, `CLAUDE.md` with Build & Run and Layout.

## 6. The first prompt for the agent

Start Claude Code in this folder and send:

```
Read CLAUDE.md, docs/STATUS.md, docs/ROADMAP.md, docs/ARCHITECTURE.md and docs/UX.md.
Build milestone M0 of docs/ROADMAP.md. Copy what docs/BOOTSTRAP.md section 3 lists as "still to copy" from ../DevHub, rename, and remove everything DevHub-specific.
After M0 run Scripts/build.sh and Scripts/test.sh, update CHANGELOG.md and docs/STATUS.md, and stop.
```

Later sessions: one milestone per session at most. The session hook prints the recent commits, the `[Unreleased]` section and `docs/STATUS.md`; the prompt is then `Continue with milestone M<n> of docs/ROADMAP.md.`

## 7. Session cadence and checks

- Every session ends with `Scripts/build.sh` clean, `Scripts/test.sh` passing, the changelog and status updated, and a commit.
- The owner runs the manual checks of the milestone from `ROADMAP.md` before the next session starts, and writes what failed into `docs/STATUS.md` under "Known gaps".
- The remote, when there is one, is pushed only by the owner until the project has run for a few sessions.
