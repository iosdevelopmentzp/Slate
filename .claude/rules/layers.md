# Layers

Full contract: `docs/ARCHITECTURE.md`. Read it before a change that adds a type.

All code lives in the local package `Packages/SlateKit`, Swift 6 language mode. One module per layer; the compiler
enforces the direction `Composition → Presentation → Domain ← Data`, Presentation also uses UI and Editor, the CLI uses Domain and Data.

| Module | Depends on | Default isolation | Holds |
|---|---|---|---|
| `SlateDomain` | nothing | nonisolated | models, values, ports, policies, codec, use cases, errors, `Ports`, `UseCases` |
| `SlateData` | Domain, GRDB, swift-markdown | nonisolated | live ports (files, index, watcher, git, screencapture, keychain), parsers, `ShellRunner`, `Ports.live()` |
| `SlateMocks` | Domain | nonisolated | `Mock*` ports, `MockVault`, `InMemoryKeyValueStore`, `Ports.mock()` |
| `SlateUI` | nothing | MainActor | shared SwiftUI blocks, `Theme`, `Tint`, formatters, hints |
| `SlateEditor` | nothing (swift-markdown) | MainActor | the TextKit 2 rich text editor, Markdown reader and writer; knows nothing about notes or files |
| `SlatePresentation` | Domain, UI, Editor, Mocks, KeyboardShortcuts | MainActor | stores, row models, mappers, views, events, `PresentationAssembly`, `AppWindows` |
| `SlateComposition` | Domain, Data, Mocks, Presentation | MainActor | `AppContainer`, URL scheme, Services, login item |
| `SlateTestSupport` | Domain | nonisolated | spies and test helpers |
| `SlateCLI` | Domain, Data, ArgumentParser | nonisolated | the `slate` command |

- Presentation imports `SlateMocks` only in `Shared/PresentationAssembly+Preview.swift`.
- `Slate/` (the app host) holds only `SlateApp.swift` and `Assets.xcassets`. No `.shared` anywhere.

Access: `package` on everything another module uses (types, members, nested types, statics, `package var body`).
Internal inside a module. `public` only on `AppContainer`, its `init()` and its `NSApplicationDelegate` methods. A struct built in another module
gets an explicit `package init` in declaration order, with the same defaults as its stored properties. A file that
uses another module's extension member imports that module. Never write `nonisolated` on a type in Domain, Data,
Mocks, TestSupport or CLI.

One top-level type per file; the file name is the type name. Exceptions by case: a `private` helper under ~30 lines,
a protocol with one trivial implementation, a `private enum Keys`, extensions of the file's own type. Other
extensions go to `<Type>+<Concern>.swift`. Every other exception is listed in `Scripts/layer-exceptions.txt`.

No comment lines in Swift (`Scripts/check-layers.sh` fails on them; `// MARK` is allowed).

Tests: Swift Testing in `Packages/SlateKit/Tests/`, one `<Type>Tests` suite per type, spies from
`SlateTestSupport`. New logic comes with a test (`.claude/rules/testing.md`, `/testing`).

After every change run `Scripts/build.sh` (runs `Scripts/check-layers.sh`, then `xcodebuild`; prints `layers: ok`
and the app path) and `Scripts/test.sh` (one passing summary line). Both must be clean before a commit.
