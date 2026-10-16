---
paths:
  - "Packages/SlateKit/Sources/SlateData/**"
  - "Packages/SlateKit/Sources/SlateMocks/**"
---

# Data and Mocks rules

## SlateData

- Implements Domain ports. Depends on SlateDomain only; every file starts with `import Foundation` and
  `import SlateDomain`. AppKit only under `SlateData/System/`. Never SwiftUI or Observation.
- Nonisolated is the module default: never write `nonisolated` on a type. A member of an actor may be `nonisolated`
  (`ShellRunner.run`).
- Access: the live repositories, runners and parsers stay internal. `package` only on what Composition or the tests
  need from outside: `Ports.live(shell:)`, `ShellRunner.init(recorder:)`, `UserDefaultsKeyValueStore.init(defaults:)`,
  `GlobalHotKey`. Tests reach the rest with `@testable import SlateData`.
- Named by technology: `FileVaultStore`, `GRDBSearchIndex`, `FSEventsVaultWatcher`, `GitHistoryRepository`,
  `ScreencaptureTool`, `KeychainSecretStore`, `URLSessionLinkTitleFetcher`.
- Everything a repository needs comes through `init`, including file roots. No repository builds another
  repository. No `.shared`. `Ports.live(shell:)` (`Assembly/Ports+Live.swift`) builds every repository once.

```swift
struct ShellWorktreeRepository: WorktreeRepository {
    let git: GitCommandRunner

    init(shell: ShellRunner) {
        git = GitCommandRunner(shell: shell)
    }
}

struct FileSlackCatalogRepository: SlackCatalogRepository {
    let fileURL: URL
}
```

- Every process goes through `ShellRunner`. Never `Process` elsewhere. Never on the main actor.
- `NSFileCoordinator` only under `Files/`. `import GRDB` only under `Index/`. `import Markdown` only under `Index/` and `Export/`.
- Parsers are pure types in their own file: text in, values out (`Git/Parsers/GitLogParser`, `GlabMergeRequestParser`,
  `SessionLogParser`, …). A parser that needs the clock takes it as a parameter. DTOs are `private` to the parser.
  A Domain model is never `Decodable` for an external format; map DTO → model explicitly.
- Raw stderr becomes the `.command(String)` case of the domain error, trimmed. Tolerated exit codes are explicit
  (`simctl boot` 149 means "already booted").
- `UserDefaults` only inside `UserDefaultsKeyValueStore`. Everything else takes a `KeyValueStore`.
- Secrets: the Jira token lives in the Keychain through `SecretStore`, travels in a request header and never appears in a log line or a command line.
- Every parser and encoder has a fixture test in `Tests/SlateDataTests/`. Code that reads files is tested over
  `TemporaryDirectory`; code that runs git or `sh` has an `…IntegrationTests` suite.

## SlateMocks

- Depends on SlateDomain only. No UI framework.
- `Mock<Thing>Repository`, one per file, internal, returning `MockData` and sleeping a little on actions.
- `MockData` is a `package enum` split into `MockData+<Domain>.swift` files with `package static` samples.
- `InMemoryKeyValueStore` (`Persistence/`) is the `KeyValueStore` for previews and tests.
- `Ports.mock()` (`Ports+Mock.swift`) builds every mock. A new port adds one line here.
