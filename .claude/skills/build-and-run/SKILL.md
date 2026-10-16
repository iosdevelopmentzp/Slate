---
name: build-and-run
description: "Build, test, smoke-run and install Slate from the command line: Scripts/build.sh (layer check plus xcodebuild), Scripts/test.sh (swift test on the package), check-layers.sh, run.sh, install.sh, swift build and swift test on Packages/SlateKit, the headless launch check, and fixes for common xcodebuild, Swift 6 compiler, layer-check and menu bar app problems."
---
> Copied from DevHub at bootstrap. Examples still name DevHub features (worktrees, simulators, git commands). Read them as patterns; the Slate types are in `docs/ARCHITECTURE.md`. Update this file when the thing it describes changes in Slate.


# Build and Run

## Commands

| Command | Result |
|---|---|
| `Scripts/build.sh` | Runs `Scripts/check-layers.sh`, then a Debug build of the app into `DerivedData/`, prints the `.app` path. Use after every code change |
| `Scripts/test.sh` | `swift test -q` on `Packages/SlateKit`, prints one summary line, forwards the exit code. Use after every code change |
| `Scripts/test.sh --skip integration` | Same without the suites named `*IntegrationTests` (the ones that run `git` and `sh`) |
| `Scripts/test.sh --filter WorktreesStoreTests` | One suite, a test target (`SlateDataTests`) or a test name. Any other `swift test` argument passes through |
| `Scripts/check-layers.sh` | The lint only. Prints `layers: ok` or every violation |
| `Scripts/build.sh Release` | Same as `build.sh` with the Release configuration |
| `Scripts/run.sh` | Debug build, quits a running Slate, opens the new one. The hammer icon appears in the menu bar |
| `Scripts/install.sh` | Release build copied to `/Applications/Slate.app` and opened. Use for daily use |

A clean `build.sh` prints `layers: ok` and the app path (plus at most one `IDERunDestination` noise line from
xcodebuild). Any other output is an error or a warning and must be fixed. A clean `test.sh` prints one
`Test run with N tests in M suites passed` line. `SKIP_LAYER_CHECK=1 Scripts/build.sh` skips the lint; use it only
while a move is half done, never before a commit.

## The package from the command line

```sh
swift build --package-path Packages/SlateKit
swift build --package-path Packages/SlateKit --target SlateDomain
swift test  --package-path Packages/SlateKit --filter SlateDomainTests
```

- `swift build` and `swift test` write to `Packages/SlateKit/.build/` (gitignored). `xcodebuild` writes to
  `DerivedData/`. The two do not share products; the first build in each is slow.
- `swift build --target <Module>` builds one module and its dependencies. Use it to find access errors bottom-up:
  Domain, then Data and Mocks, then UI, then Presentation.
- `#Preview` blocks compile under `swift build`. They render only in Xcode.

## Xcode

- Open `Slate.xcodeproj`. The package shows under Package Dependencies as `SlateKit`.
- `xcodebuild -list -project Slate.xcodeproj` shows the schemes `Slate` and `SlateComposition` (Xcode creates the
  second one for the package product). Build and preview with `Slate`.
- Previews in package files render through the `Slate` scheme. A screen preview needs `.previewEnvironment()`.
- An editor (SourceKit) may show "No such module 'SlateDomain'" in a package file before the first build or after
  a clean. That is index noise. When `swift build` and `Scripts/build.sh` are clean, the code is fine.

## Lint

`Scripts/check-layers.sh` checks what the compiler cannot (`docs/ARCHITECTURE.md` section 9): imports per module,
AppKit only in `SlateData/Workspace/`, `.shared`, `Process(` only in `ShellRunner.swift`, `UserDefaults` only in
`UserDefaultsKeyValueStore.swift`, `NSPasteboard` only in `PasteboardWriter.swift`, `import SlateMocks` in
Presentation only in `PresentationAssembly+Preview.swift`, no top-level `nonisolated` in Domain, Data and Mocks,
`public` only in SlateComposition, `@testable` only under `Tests/`, `Slate/` holds only `SlateApp.swift`, and the
file rule (one top-level type per file, the name matches) over `Sources/` and `Tests/`.
`Scripts/layer-exceptions.txt` lists files allowed to break the file rule, with a reason. Fix the code, not the
pattern; widen a pattern only for a false match on a word inside a string.

## Headless smoke check

Confirms the app starts and stays alive without opening it in the menu bar:

```sh
APP="$(Scripts/build.sh | tail -1)"
"$APP/Contents/MacOS/Slate" & PID=$!
sleep 3
kill -0 $PID && echo alive || echo crashed
kill $PID
```

## Build settings that matter

App target, in `Slate.xcodeproj/project.pbxproj`:

| Setting | Value | Why |
|---|---|---|
| `ENABLE_APP_SANDBOX` | `NO` | shell commands |
| `CODE_SIGN_STYLE` / identity | Automatic, no team | ad-hoc "Sign to Run Locally" |
| `INFOPLIST_KEY_LSUIElement` | `YES` | no Dock icon |
| `MACOSX_DEPLOYMENT_TARGET` | `26.4` | |
| `SWIFT_VERSION` | `6.0` | Swift 6 language mode |
| `SWIFT_DEFAULT_ACTOR_ISOLATION` | `MainActor` | |
| `SWIFT_APPROACHABLE_CONCURRENCY`, `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY` | `YES` | the package turns on the same features in `Package.swift` |

The local package reference (`XCLocalSwiftPackageReference "Packages/SlateKit"`) and the `SlateComposition` product
dependency are in `project.pbxproj`. Change settings with `sed` or `perl -pi` on the matching line. Never touch the
file reference sections. Package settings live in `Packages/SlateKit/Package.swift`.

## Common problems

| Symptom | Fix |
|---|---|
| `'X' is inaccessible due to 'internal' protection level` | Another module uses it: add `package` (and an explicit `package init` for a struct) |
| `… is not available due to missing import of defining module 'SlateUI'` | `MemberImportVisibility`: add `import SlateUI` (or `SlateDomain`) to that file |
| swift-frontend crashes in IRGen on a `Binding(get:set:)` or a callback | A partly applied MainActor method was passed where an `@isolated(any)` closure is expected. Wrap it: `set: { build.setIncremental($0) }` instead of `set: build.setIncremental` |
| `xcodebuild: error: … does not contain a scheme named "Slate"` | Open the project in Xcode once, or build with `-target Slate` instead of `-scheme` |
| "No such module" only in the editor | Index noise; build once. Trust `swift build` and `Scripts/build.sh` |
| A test hangs or fails only sometimes | A `Task` inside a store is not awaited. Use `waitUntil { … }`, never `Task.sleep` (`/testing`) |
| Integration suites fail on a machine without git setup | They need `git` in `PATH` and `/bin/sh`. `Scripts/test.sh --skip integration` |
| Build ok, nothing visible | The app has no window and no Dock icon. Look for the hammer icon in the menu bar. `pgrep -x Slate` confirms it runs |
| Two hammer icons | Two instances. `pkill -x Slate`, then `Scripts/run.sh` |
| `resource fork, Finder information, or similar detritus not allowed` | `xattr -cr Slate/` |
| Preview fails to render | A screen preview must include `.previewEnvironment()`; a row preview uses `<Row>Model.preview`. Select the `Slate` scheme |
| `layers: SlatePresentation imports SlateData` | The view or store reached past the port: inject the port or the use case through `init`, or add the call to `AppActions` |
| `layers: … holds more than one top-level type` | Split the file, or make the helper `private` when only that file uses it |
| Hover actions flicker | Keep actions in the tree and toggle `opacity`, see `/ui-components` |
