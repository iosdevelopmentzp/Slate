---
name: testing
description: "How Slate is tested: Swift Testing conventions in Packages/SlateKit/Tests, the SlateTestSupport spies (Spy<Port>, Ports.spies(keyValues:), PortSpies), StoreHarness for store tests, fixtures and samples, TemporaryDirectory, waitUntil, integration suites over real git and sh, running and filtering with Scripts/test.sh, what not to test, and how to add a test for a new mapper, store, parser, policy or use case. Load before writing or changing any test, adding a port (it needs a spy), or when Scripts/test.sh fails."
---
> Matches the Slate code since M1.


# Testing

Short rules: `.claude/rules/testing.md`. Contract: `docs/ARCHITECTURE.md` section 12. All paths below are under
`Packages/SlateKit/`.

## Targets

| Target | Tests | Imports |
|---|---|---|
| `Tests/SlateDomainTests/` | codec, policies, values, every use case over spies | `@testable import SlateDomain`, `SlateTestSupport` |
| `Tests/SlateDataTests/` | file-bound code over `TemporaryDirectory`, the in-memory index, the coalescer, `*IntegrationTests` (real `sh`, real FSEvents) | `@testable import SlateData`, `SlateTestSupport` |
| `Tests/SlateEditorTests/` | editor values (M2 adds the highlighter and list commands) | `@testable import SlateEditor` |
| `Tests/SlateUITests/` | formatters, `Theme` | `@testable import SlateUI` |
| `Tests/SlatePresentationTests/` | `Shared/` objects, mappers next to their feature, stores over the harness | `@testable import SlatePresentation`, `SlateMocks`, `SlateTestSupport` |

Folders mirror `Sources/`: `NoteListStoreTests` lives in `SlatePresentationTests/Features/NoteList/`. Domain and Data
test targets are nonisolated; UI, Editor and Presentation test targets are MainActor, like their modules. About 220
tests in about 57 suites run in about 5 s (the watcher integration tests take most of it).

## Running

```sh
Scripts/test.sh                                # everything, one summary line, exit code forwarded
Scripts/test.sh --skip integration             # without the *IntegrationTests suites
Scripts/test.sh --filter EditorStoreTests      # one suite
Scripts/test.sh --filter SlateDomainTests      # one target
swift test --package-path Packages/SlateKit --filter X   # the full output, when the summary is not enough
```

`test.sh` keeps only failure lines (`✘`, `recorded an issue`, `error:`) and the final `Test run with …` line.

## Conventions

- `import Testing`, `@Suite struct <Type>Tests`, `@Test func <sentence>()`, `#expect`, `#require`.
- One suite per type under test, file `<Type>Tests.swift`. The lint applies the file rule to Tests.
- Arrange, act, assert, separated by one empty line. One behaviour per test.
- No comments, `== false`. A `private` helper under ~30 lines may stay in the test file; a helper used by two
  files goes to the target's `Support/` folder; a helper for two targets goes to `SlateTestSupport`.
- Raw strings with a `"#` inside (`"#tag"`) need `##"…"##`.

## Spies (`Sources/SlateTestSupport/`)

One spy per port: `SpyVaultFileStore`, `SpySearchIndex`, `SpyIndexedNoteBuilder`, `SpyVaultWatcher`,
`SpyTrashRepository`, `SpyTemplateRepository`, `SpyVaultConfigRepository`, `SpyClock`, `SpyKeyValueStore`, plus
`SpyCommandRecorder` (`records`) and `CallbackRecorder<Value>`.

- The file, index, trash and config spies are **in-memory fakes** that also record `calls: [Call]`. A use case or a
  store test works on them like on a real vault: `spies.files.seed(path, text)`, `spies.files.text(at:)`,
  `spies.files.paths`, `spies.index.indexed`, `spies.config.config`.
- Scripted failures: `spies.files.writeError`, `spies.index.summariesError`, `spies.config.spacesError`
  (`TestError.scripted("…")`).
- `SpyClock.current` is fixed (2027-01-15 08:00 UTC, the clock's zone is +03:00); `SpyVaultWatcher.send(_:)` pushes
  a change to every subscriber.
- `NoteText.make(id:title:type:pinned:status:body:)` builds the text of a note file with a header.
- `let (ports, spies) = Ports.spies()` gives a full `Ports`; pass `keyValues:` to share a store (Presentation tests
  use `InMemoryKeyValueStore` from SlateMocks).

```swift
let (ports, spies) = Ports.spies()
spies.files.seed(VaultPath(rawValue: "Inbox/Old.md"), NoteText.make(id: "a", title: "Old", body: "Body"))
let document = try NoteCodec.decode(try await spies.files.read(VaultPath(rawValue: "Inbox/Old.md")))

let result = try await UseCases(ports: ports).rename.execute(document, title: "New name", body: "Body")

#expect(result.document?.path == VaultPath(rawValue: "Inbox/New name.md"))
#expect(spies.index.calls == [.remove(VaultPath(rawValue: "Inbox/Old.md")), .upsert(VaultPath(rawValue: "Inbox/New name.md"))])
```

### Add a spy for a new port

1. `Sources/SlateTestSupport/Spy<Port>.swift`: a `final class … : <Port>, @unchecked Sendable` with an `NSLock`
   around every stored property, a `Call` enum, in-memory state or scripted answers.
2. A field in `PortSpies.swift` and one argument in `Ports+Spies.swift`.

## Store tests

`Tests/SlatePresentationTests/Support/StoreHarness.swift` builds the same graph as `PresentationAssembly` over spies:
`ports`, `spies`, `useCases`, `keyValues`, `events`, `activity`, `navigator`, `toaster` (writes into `copied`), one
`lazy var` per store (`vault`, `noteList`, `editor`) and `feed`. It records every posted event in `posted`
(`clearPosted()`). `seed(_:id:title:type:pinned:body:)` writes a note, `index()` runs a full reindex,
`document(at:)` reads a note back.

```swift
@MainActor
@Suite struct EditorStoreTests {
    private let harness = StoreHarness()

    @Test func externalChangeReloadsACleanEditor() async throws {
        let path = harness.seed("Inbox/A.md", id: "a", body: "Body")
        try await harness.index()
        harness.navigator.select(NoteID(rawValue: "a"))
        await harness.editor.open(NoteID(rawValue: "a"))
        harness.seed(path.rawValue, id: "a", title: "A", body: "From Obsidian")

        harness.events.post(.vaultChanged([path]))

        try await waitUntil { harness.editor.text == "From Obsidian" }
    }
}
```

- `async` store methods: `await` them. Methods that start a `Task`: `try await waitUntil { … }` on the state.
- A store subscribes to events in its `init`, and the harness stores are lazy: touch the store first
  (`_ = harness.editor`) when the test posts an event before it uses the store.
- Autosave waits 500 ms; `waitUntil` (2 s) covers it. For the 1.5 s title commit, call `editor.flush()` instead.

## Files and processes

- `TemporaryDirectory()` creates a unique folder and removes it in `deinit`. `write(_:to:)` creates parent folders;
  `path(_:)` gives a path inside. Never write to the real home folder or `UserDefaults.standard`
  (`UserDefaults(suiteName:)` for `UserDefaultsKeyValueStore`).
- Integration suites: `@Suite(.tags(.integration)) struct <Type>IntegrationTests`. Both the tag and the name are
  required: `Scripts/test.sh --skip integration` skips by the name. `.integration` is declared in
  `SlateDataTests/Support/Tag+Integration.swift`.
- `FSEventsVaultWatcherIntegrationTests` wait one second for the setup events to pass, and use one consumer task for
  the whole test: cancelling a consumer finishes the stream (`docs/PLAYBOOK.md` section 5).

## `waitUntil`

`try await waitUntil(timeout: .seconds(2)) { condition }` checks the condition on the main actor, yields between
checks and throws `TestError.timedOut` after the timeout. It replaces `Task.sleep` in unit tests. Only the watcher
integration tests sleep, because FSEvents has its own latency.

## What not to test, and why

- SwiftUI views, `AppWindows`, `RootView`, `FirstLaunchWindow`: no logic in them (mappers and stores hold it). The
  preview is the check.
- Text from `relativeDescription`, `ByteFormat`, `ByteCountFormatter`: it depends on the locale and the clock.
  Assert nil, not empty, or a prefix only.
- `AppContainer`: it touches `UserDefaults.standard` and the real windows.

## Add a test for…

| New code | Test file | What to pin |
|---|---|---|
| a mapper | `SlatePresentationTests/Features/<Feature>/Models/<Row>MapperTests.swift` | one `@Test` per input state: icon, tint, text, hint, badges |
| a store action | `SlatePresentationTests/Features/<Feature>/<Name>StoreTests.swift` (+ `lazy var` in `StoreHarness`) | files and index after the action, state before and after, posted events, toast, activity line, failure path |
| a parser or codec | `SlateDomainTests/Codec/` or `SlateDataTests/<Folder>/` | every field, empty input, malformed input, round trip |
| a policy | `SlateDomainTests/Policies/<Policy>Tests.swift` | a table of inputs and decisions (`@Test(arguments:)`), every branch |
| a use case | `SlateDomainTests/UseCases/<Name>UseCaseTests.swift` | port calls per path over `Ports.spies()`, the result, the error path |
| file-bound Data code | `SlateDataTests/Files/<Type>Tests.swift` over `TemporaryDirectory` | the files on disk after the call |
| a formatter | `SlateUITests/Formatters/<Formatter>Tests.swift` | exact text when it does not depend on locale or clock |

Then `Scripts/test.sh` and `Scripts/build.sh` (the lint checks the test files too).
