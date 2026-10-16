# Slate architecture

The contract for every change in `Packages/SlateKit/` and `Slate/`. It copies the proven shape of `../DevHub` (`docs/ARCHITECTURE.md` there) and adds what a notes app needs: a file store, an index, an editor module and a CLI. When this file and the code disagree, fix one of them in the same session.

---

## 1. Layers and modules

```
Composition  →  Presentation  →  Domain  ←  Data
                  ↓        ↓
                 UI      Editor
CLI  →  Domain, Data
```

One local Swift package `Packages/SlateKit`, tools 6.2, Swift 6 language mode. The compiler enforces the direction: a module imports only what `Package.swift` lists.

| Module | Depends on | Default isolation | Holds |
|---|---|---|---|
| `SlateDomain` | nothing | nonisolated | models, values, ports, policies, use cases, errors, `Ports`, `UseCases` |
| `SlateData` | Domain, GRDB, swift-markdown | nonisolated | live implementations of the ports, parsers, `ShellRunner`, `Ports.live(…)` |
| `SlateMocks` | Domain | nonisolated | `Mock*` ports, `MockVault` sample data, `InMemoryKeyValueStore`, `Ports.mock()` |
| `SlateUI` | nothing in the package | MainActor | shared SwiftUI blocks, `Theme`, `Tint`, formatters, hints |
| `SlateEditor` | nothing in the package | MainActor | the Markdown text view on TextKit 2, highlighters, list commands, paste detection, image and checkbox rendering (section 6) |
| `SlatePresentation` | Domain, UI, Editor, Mocks, KeyboardShortcuts | MainActor | stores, row models and mappers, views, events, `PresentationAssembly`, `AppWindows` |
| `SlateComposition` | Domain, Data, Mocks, Presentation | MainActor | `AppContainer` (the only `public` type), URL scheme handling, Services provider, launch at login |
| `SlateTestSupport` | Domain | nonisolated | `Spy<Port>` for every port, `TemporaryDirectory`, `waitUntil`, fixtures |
| `slate` (executable, target `SlateCLI`) | Domain, Data, swift-argument-parser | nonisolated | the command line tool (section 9.3) |

- `SlatePresentation` imports `SlateMocks` in one file only: `Shared/PresentationAssembly+Preview.swift`.
- `SlateEditor` imports AppKit, SwiftUI, Foundation and Observation only. It knows nothing about notes, vaults or the index. This keeps the riskiest code replaceable.
- The app target `Slate` is `Slate/SlateApp.swift` plus `Assets.xcassets` and `Slate.entitlements` (empty). It links the product `SlateComposition`.

### 1.1 `Package.swift`

```swift
// swift-tools-version: 6.2
import PackageDescription

let shared: [SwiftSetting] = [
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
]
let mainActor: [SwiftSetting] = shared + [.defaultIsolation(MainActor.self)]

let package = Package(
    name: "SlateKit",
    platforms: [.macOS("26.4")],
    products: [
        .library(name: "SlateComposition", targets: ["SlateComposition"]),
        .executable(name: "slate", targets: ["SlateCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "<latest release>"),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "<latest release>"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "<latest release>"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "<latest release>"),
    ],
    targets: [
        .target(name: "SlateDomain", swiftSettings: shared),
        .target(name: "SlateData", dependencies: [
            "SlateDomain",
            .product(name: "GRDB", package: "GRDB.swift"),
            .product(name: "Markdown", package: "swift-markdown"),
        ], swiftSettings: shared),
        .target(name: "SlateMocks", dependencies: ["SlateDomain"], swiftSettings: shared),
        .target(name: "SlateUI", swiftSettings: mainActor),
        .target(name: "SlateEditor", swiftSettings: mainActor),
        .target(name: "SlatePresentation", dependencies: [
            "SlateDomain", "SlateUI", "SlateEditor", "SlateMocks",
            .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
        ], swiftSettings: mainActor),
        .target(name: "SlateComposition", dependencies: ["SlateDomain", "SlateData", "SlateMocks", "SlatePresentation"], swiftSettings: mainActor),
        .target(name: "SlateTestSupport", dependencies: ["SlateDomain"], swiftSettings: shared),
        .executableTarget(name: "SlateCLI", dependencies: [
            "SlateDomain", "SlateData",
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ], swiftSettings: shared),
        .testTarget(name: "SlateDomainTests", dependencies: ["SlateDomain", "SlateTestSupport"], swiftSettings: shared),
        .testTarget(name: "SlateDataTests", dependencies: ["SlateData", "SlateMocks", "SlateTestSupport"], swiftSettings: shared),
        .testTarget(name: "SlateEditorTests", dependencies: ["SlateEditor"], swiftSettings: mainActor),
        .testTarget(name: "SlateUITests", dependencies: ["SlateUI"], swiftSettings: mainActor),
        .testTarget(name: "SlatePresentationTests", dependencies: ["SlatePresentation", "SlateMocks", "SlateTestSupport"], swiftSettings: mainActor),
    ]
)
```

Pin each dependency to its latest release at bootstrap and write the versions into `docs/STATUS.md`. No other package without an ADR.

---

## 2. Folder map

```
Slate.xcodeproj                  app target Slate, links SlateComposition
Slate/
  SlateApp.swift                 @main, Settings { EmptyView() }, NSApplicationDelegateAdaptor, keeps AppContainer.live() alive
  AppDelegate.swift              application(_:open:) → container.handle(urls:); applicationWillTerminate → container.flush()
  Assets.xcassets
  Slate.entitlements             empty
Packages/SlateKit/
  Package.swift
  Sources/
    SlateDomain/
      Models/                    Note, NoteDocument, NoteSummary, NoteHeader, NoteType, Space, Tag, TodoItem, Attachment, Link, SearchHit, Snapshot, TrashItem, CloudStatus, ConflictVersion, ActionDefinition, LinkPattern, SmartView, IssueDetails
      Values/                    NoteID, VaultPath, SpaceName, Stem, ContentHash, TicketKey, BranchName
      Ports/                     one protocol per file (section 4.3)
      Policies/                  pure functions (section 4.4)
      Codec/                     NoteCodec, FrontmatterParser, FrontmatterWriter
      UseCases/                  one struct per file (section 4.5)
      Errors/                    SlateError and friends, LocalizedError
      Assembly/                  Ports, UseCases(ports:)
    SlateData/
      Files/                     FileVaultStore, FileAttachmentStore, FileTrashRepository, FileTemplateRepository, FileVaultConfigRepository, FileJournalStore, VaultBootstrap
      Index/                     GRDBSearchIndex, IndexSchema, IndexedNoteBuilder (swift-markdown), FTSMatchBuilder
      Watch/                     FSEventsVaultWatcher, ChangeCoalescer
      Shell/                     ShellRunner, ShellResult, CommandFormatter
      History/                   GitHistoryRepository, GitLogParser
      Capture/                   ScreencaptureTool
      Cloud/                     UbiquityStatusProvider
      Network/                   URLSessionLinkTitleFetcher, JiraIssueClient (+ private DTOs)
      Secrets/                   KeychainSecretStore
      Persistence/               UserDefaultsKeyValueStore
      System/                    AppKit allowed here only: WorkspaceOpener (open, reveal), SystemClock
      Actions/                   ShellActionRunner
      Export/                    SlackFormatExporter, HTMLExporter (swift-markdown allowed)
      Assembly/                  Ports+Live.swift
    SlateMocks/                  Mock<Port> one per file, MockVault (sample notes), InMemoryKeyValueStore, Ports+Mock.swift
    SlateUI/                     RowContainer, ListState, Tag, IconButton, OverflowMenu, InlineConfirmation, SearchField, Chip, Theme, Tint, Tint+Color, Formatters/, Hint/, CopyOnClick
    SlateEditor/
      MarkdownEditorView.swift   NSViewRepresentable, the only package-visible entry point
      EditorConfiguration.swift  fonts, sizes, colours as plain values
      EditorHandlers.swift       closures the host supplies (section 6.1)
      Core/                      MarkdownTextView (NSTextView subclass), EditorTextStorageDelegate, ParagraphStyler (NSTextContentStorageDelegate)
      Highlighting/              MarkdownLineScanner, LineState, FenceTracker, CodeHighlighter, languages/ (one file per language)
      Commands/                  ListEditing, CheckboxToggle, WrapSelection, MoveLine, DuplicateLine
      Paste/                     PasteClassifier, PasteHandler (NSPasteboard allowed here)
      Rendering/                 ImageLayoutFragment, CheckboxGlyph, CodeBlockBackground, LinkChipAttributes, CopyButtonOverlay
      Find/                      FindBar (P1)
    SlatePresentation/
      Shared/                    Surface, Navigator, ActivityLog, ActivityRecorder (CommandRecording → ActivityLog), Toaster, PasteboardWriter, SettingsStore, WindowLayout, AppActions, ActionRunner, RefreshTask, VaultChangeFeed, lookup protocols, PresentationAssembly (+Preview), View+Inject, View+PreviewEnvironment
      Shared/Events/             AppEvent, AppEvents, SubscriptionToken
      Shell/                     AppWindows (status item, panel, windows, capture panel, floating notes), RootView, HeaderView, FooterView, SidebarView, SpacePicker, drag and resize
      Features/Vault/            VaultStore, Models/, Views/
      Features/NoteList/         NoteListStore, Models/ (NoteRowModel, NoteRowMapper), Views/
      Features/Editor/           EditorStore, NoteDetailView (M0 stand-in), NoteHeaderView, ConflictBanner, PasteAsCodeBar, Views/
      Features/Search/           SearchStore, SearchQueryModel, Views/ (palette, results)
      Features/Capture/          CaptureStore, Views/
      Features/Todos/            TodoStore, Models/, Views/           (P1)
      Features/Daily/            DailyStore, Views/                    (P1)
      Features/History/          HistoryStore, Views/                  (P1)
      Features/Settings/         SettingsView, Doctor
      Features/Activity/         ActivityView
    SlateComposition/            AppContainer, URLCommandParser, URLCommandHandler, ServicesProvider, LoginItem
    SlateTestSupport/            Spy<Port> per port, PortSpies, Ports+Spies, TemporaryDirectory, WaitUntil, TestError, VaultFixture (writes a sample vault into a temporary folder)
    SlateCLI/                    SlateCommand (root), New, Open, Append, Today, Search, List, Path, CLIContainer
  Tests/
    SlateDomainTests/ SlateDataTests/ (+ Integration/) SlateEditorTests/ SlateUITests/ SlatePresentationTests/
Scripts/
  build.sh test.sh check-layers.sh layer-exceptions.txt run.sh install.sh generate-vault.sh
docs/
  SPEC.md STORAGE-FORMAT.md ARCHITECTURE.md UX.md ROADMAP.md PLAYBOOK.md BOOTSTRAP.md STATUS.md adr/
```

---

## 3. Access and imports

Same as DevHub:

- `package` on every type and member another module uses, including `package init`, `package var body`, `package static let`. Internal for what one module uses alone. `public` only on `AppContainer` and `AppContainer.live()`; the CLI target is an executable and needs no `public`.
- A struct built in another module gets an explicit `package init` in declaration order with the same defaults as its stored properties.
- `MemberImportVisibility`: a file that uses a member from another module imports that module.
- Domain, Data, Mocks, TestSupport and CLI never write `nonisolated` on a type. UI, Editor, Presentation and Composition are MainActor by module default.
- Never `MainActor.assumeIsolated`. `@unchecked Sendable` only for a class that guards its own state with a lock or a serial queue (the spies, `InMemoryKeyValueStore`, `ChangeCoalescer`).
- One top-level type per file; the file name is the type name; `<Type>+<Concern>.swift` for extensions. Exceptions by case: a `private` helper under about 30 lines next to its only user, a protocol with one trivial implementation, a `private enum Keys`. Everything else is listed in `Scripts/layer-exceptions.txt` with a reason. A file over about 300 lines gets split.
- No comments. No `.shared`. No singletons.

---

## 4. Domain

### 4.1 Models (value types)

| Type | Fields |
|---|---|
| `NoteSummary` | `id`, `path`, `space`, `stem`, `title`, `type`, `status`, `ticket`, `pinned`, `created`, `updated`, `preview`, `openTodos`, `attachmentCount`, `hasCode`, `hasImage`, `inCloud`, `inConflict`, `headerOpaque` |
| `NoteDocument` | `id`, `path`, `header: NoteHeader`, `body: String`, `hash: ContentHash`, `rawHeader: String?` (set when opaque) |
| `NoteHeader` | the known keys of `STORAGE-FORMAT.md` 2.2 as optionals, plus `unknownLines: [String]` |
| `NoteDraft` | `title`, `type`, `space`, `bodyOverride: String?`, `header fields` |
| `NoteType` | `name`, `title`, `icon`, `defaultSpace`, `fields`, `titlePattern`, `branchPattern`, `statuses`, `doneStatuses` |
| `Space` | `folder`, `icon`, `defaultType`, `noteCount` |
| `TodoItem` | `noteID`, `line`, `text`, `isDone`, `due` |
| `Attachment` | `file`, `relativeLink`, `kind` (`image`, `file`) |
| `Link` | `kind` (`wiki(target, alias, heading)`, `url`, `pattern(id)`), `range` |
| `SearchQuery` | `terms: [String]`, `phrases: [String]`, `filters: [SearchFilter]`, `excludes` |
| `SearchHit` | `summary`, `snippet`, `matchRanges`, `score` |
| `VaultChange` | `paths: [VaultPath]`, `kind` (`changed`, `removed`, `renamed(from)`) |
| `CloudStatus` | `local`, `current`, `downloading(progress)`, `notDownloaded`, `conflict(count)` |
| `ConflictVersion` | `id`, `modified`, `deviceName`, `size` |
| `Snapshot` | `hash`, `date`, `message` |
| `TrashItem` | `path`, `originalPath`, `trashedAt` |
| `LinkPattern`, `SmartView`, `ActionDefinition`, `IssueDetails` | per `STORAGE-FORMAT.md` section 7 |

Models hold no `Color`, no SF Symbol chosen by the app (an icon name read from a config file is data and stays), no display strings.

### 4.2 Values

`NoteID` (UUID string), `VaultPath` (relative path with `/` separators, never absolute, knows its `space`, `stem`, `depth`, `folder`), `SpaceName`, `Stem`, `ContentHash` (SHA-256 hex), `TicketKey` (validated by the pattern from Settings), `BranchName`.

### 4.3 Ports

Protocols with `async throws` methods. Long work returns `AsyncStream`. A port never exposes a file descriptor, SQL, a command line or raw output.

| Port | Methods | Live implementation |
|---|---|---|
| `VaultFileStore` | `enumerate() -> [FileMeta]`, `read(VaultPath) -> FileContents` (bytes, hash, meta), `write(VaultPath, Data, expected: ContentHash?) -> WriteResult` (`.written(hash)`, `.conflict(diskHash)`), `move(from, to)`, `remove(VaultPath)`, `exists`, `createFolder` | `FileVaultStore` |
| `SearchIndex` | `summaries(space:, sort:)`, `summary(id:)`, `byTicket(_:)`, `byStem(_:)`, `search(SearchQuery, limit:)`, `linksTo(stem:)`, `todos(open:)`, `tags()`, `upsert(IndexedNote)`, `remove(path:)`, `allMetas()`, `reset()` | `GRDBSearchIndex` |
| `IndexedNoteBuilding` | `build(document, meta) -> IndexedNote` (uses swift-markdown) | `IndexedNoteBuilder` |
| `VaultWatching` | `changes() -> AsyncStream<VaultChange>` | `FSEventsVaultWatcher` |
| `AttachmentStore` | `importData(Data, ext:, source:) -> Attachment`, `importFile(URL) -> Attachment`, `absoluteURL(for: relativeLink, from: VaultPath)`, `allFiles()`, `moveToTrash(file)` | `FileAttachmentStore` |
| `TrashRepository` | `trash(VaultPath) -> TrashItem`, `restore(TrashItem) -> VaultPath`, `items()`, `purge(olderThan:) -> Int` | `FileTrashRepository` |
| `TemplateRepository` | `body(for: NoteType) -> String`, `ensureDefaults()` | `FileTemplateRepository` |
| `VaultConfigRepository` | `spaces()`, `saveSpaces`, `linkPatterns()`, `views()`, `types()`, `actions()`, `ensureDefaults(from: TrackerSettings)` | `FileVaultConfigRepository` |
| `JournalStore` | `save(id, text)`, `load(id) -> (text, date)?`, `clear(id)` | `FileJournalStore` |
| `ScreenCapturing` | `captureRegion(to: URL) -> Bool`, `captureWindow(to: URL) -> Bool` | `ScreencaptureTool` |
| `HistoryRepository` | `ensureRepository()`, `snapshot(message:) -> Bool`, `history(of: VaultPath) -> [Snapshot]`, `contents(of:, at:) -> Data`, `push() -> Bool`, `isAvailable` | `GitHistoryRepository` |
| `CloudStatusProviding` | `status(of: VaultPath) -> CloudStatus`, `startDownload(VaultPath)`, `conflictVersions(VaultPath) -> [ConflictVersion]`, `keep(version:, for:)`, `isCloudFolder(URL) -> Bool` | `UbiquityStatusProvider` |
| `LinkTitleFetching` | `title(for: URL) -> String?` (2 s timeout) | `URLSessionLinkTitleFetcher` |
| `IssueTrackerClient` | `issue(TicketKey) -> IssueDetails` | `JiraIssueClient` |
| `SecretStore` | `get(key)`, `set(key, value)`, `remove(key)` | `KeychainSecretStore` |
| `KeyValueStore` | `string/bool/int/data(forKey:)`, setters | `UserDefaultsKeyValueStore` |
| `Clock` | `now() -> Date`, `timeZone` | `SystemClock` |
| `ActionRunning` | `run(ActionDefinition, environment:) -> ActionOutput` | `ShellActionRunner` |
| `WorkspaceOpening` | `open(URL)`, `reveal(URL)`, `quickLook(URL)` | `WorkspaceOpener` |
| `CommandRecording` | `record(CommandRecord)` | `ActivityLog` conformance in Presentation |

`Ports` (Domain `Assembly/Ports.swift`) is a struct with one property per port. `Ports.live(vault:appSupport:shell:recorder:)` in Data, `Ports.mock()` in Mocks, `Ports.spies(keyValues:)` in TestSupport.

Since M0 the code has three ports: `keyValues`, `index` (`SearchIndex.summaries(space:)` only) and `config` (`VaultConfigRepository.spaces()` only). Until a port has a live implementation, `Ports.live(pending:)` takes it from the `pending` value; `AppContainer.live()` passes `Ports.mock()`. Each milestone that adds a live type moves its port out of `pending`, and M1 removes the parameter.

### 4.4 Policies (pure, `enum XPolicy { static func … }`)

| Policy | Does |
|---|---|
| `StemPolicy` | `stem(forTitle:)`, `unique(_, among:)` per `STORAGE-FORMAT.md` 3.1 |
| `SlugPolicy` | branch slug, `renderBranch(pattern:, ticket:, title:)` |
| `TitlePolicy` | `titlePattern` rendering, split `ABC-123 Title` into ticket and title using the tracker regex |
| `WikilinkPolicy` | `extract(body) -> [Link]`, `rewrite(body, old:, new:) -> String`, `resolve(target, candidates:, from:) -> NoteSummary?` |
| `TodoLinePolicy` | `parse(line) -> TodoItem?`, `toggle(line) -> String`, `cycle(line) -> String` |
| `SectionAppendPolicy` | `append(text, toSection:, in body:) -> String` per `STORAGE-FORMAT.md` 4 |
| `DailyPolicy` | `stem(for date)`, `logLine(time, text)`, `carryOver(from previousBody) -> [String]` |
| `TemplateRenderer` | placeholders, `{{cursor}}` offset |
| `SearchQueryParser` | text → `SearchQuery` |
| `ConflictPolicy` | `decide(loadedHash, diskHash, isDirty, ownWrites) -> .ignore | .reload | .conflict` |
| `PasteKindPolicy` | `classify(text) -> .plain | .code(language?) | .url(URL)` |
| `LinkPatternPolicy` | `matches(body, patterns, excluding code ranges) -> [Link]`, `shortForm(for url, patterns)` |
| `PreviewPolicy` | strip Markdown marks, first 200 characters |
| `TrashRetentionPolicy` | which items are due for purge |
| `HeaderDefaultsPolicy` | header defaults per type and space |
| `SlackFormatPolicy` | Markdown → Slack text (F6) |

Every policy has a test file with fixtures.

### 4.5 Use cases (`struct XUseCase: Sendable`, ports as `let`, one entry point)

| Use case | Ports | Does |
|---|---|---|
| `CreateNoteUseCase` | config, templates, files, index, builder, clock | type defaults, title and ticket split, unique stem, template render, write, index, returns the document and the caret offset |
| `SaveNoteUseCase` | files, index, builder, journal, clock | encode, `updated` only when changed, coordinated write with expected hash, index upsert, journal clear; returns `.saved(hash)` or `.conflict(diskHash)` |
| `RenameNoteUseCase` | files, index, builder | per `STORAGE-FORMAT.md` 3.3, returns `RenameReport` (new path, rewritten files, failures) |
| `MoveNoteUseCase` | files, index | move to depth 1 of the space, unique stem, index update |
| `TrashNoteUseCase`, `RestoreNoteUseCase`, `PurgeTrashUseCase` | trash, index, clock | |
| `QuickCaptureUseCase` | create, append (as nested use cases) | capture input → new note or Today line |
| `EnsureDailyNoteUseCase` | index, files, create, clock | today's note, carry-over block |
| `AppendToNoteUseCase` | index, files, builder, ensureDaily, clock | target by `today`, `ticket`, `id` or `path`; creates a task note for an unknown ticket; section append |
| `AttachScreenshotUseCase` | capture, attachments, clock | temp file → attachment → Markdown to insert, `nil` when cancelled |
| `ImportAttachmentUseCase` | attachments | data or file → Markdown |
| `ReindexVaultUseCase` | files, index, builder, cloud | full or paths; compare `(mtime, size)` then hash; reports progress through an `AsyncStream<IndexProgress>` |
| `ToggleTodoUseCase` | files, index, builder | edit one line in a file by number, coordinated |
| `SnapshotHistoryUseCase` | history, clock, kv | throttle, snapshot when dirty, optional push |
| `RestoreVersionUseCase` | history, save | write the old content through `SaveNoteUseCase` |
| `RunActionUseCase` | actions, files, index | environment from the note, output routing |
| `CleanAttachmentsUseCase` | index, attachments | unreferenced files to trash |
| `ResolveConflictVersionUseCase` | cloud, files, index | keep current, keep other, keep both |

A one-step action (search, list, load) is not a use case: the store calls the port. Use cases never log, toast or touch UI state.

---

## 5. Data

- A live implementation is named by its technology: `FileVaultStore`, `GRDBSearchIndex`, `FSEventsVaultWatcher`, `GitHistoryRepository`, `ScreencaptureTool`, `UbiquityStatusProvider`, `KeychainSecretStore`, `URLSessionLinkTitleFetcher`, `JiraIssueClient`.
- Every implementation takes what it needs in `init`: the vault URL, the Application Support folder, `ShellRunner`, a `KeyValueStore`. No implementation builds another. No `.shared`.
- `NSFileCoordinator` only in `Files/`. `Process` only in `ShellRunner.swift`. `UserDefaults` only in `UserDefaultsKeyValueStore.swift`. `NSWorkspace` and AppKit only in `System/`. GRDB only in `Index/`. `Markdown` (swift-markdown) only in `Index/IndexedNoteBuilder.swift` and `Export/`.
- Parsers are pure, in their own files, with private DTOs: `FrontmatterParser` lives in Domain (`Codec/`) because the CLI and the app both need it and it has no dependency; `GitLogParser`, Jira DTOs live in Data.
- `ShellRunner` is DevHub's: an `actor`, `/usr/bin/env` launch, reads on a dedicated queue, streaming with cancellation, every run reported to `CommandRecording`. Copy it (`PLAYBOOK.md` section 7).
- The watcher's own-writes filter: `FileVaultStore` records `(path, hash, date)` of each write in a small shared `OwnWrites` object; `FSEventsVaultWatcher` drops an event whose path has an own write within two seconds and the same hash on disk.

---

## 6. The editor module

### 6.1 Contract

```swift
package struct MarkdownEditorView: NSViewRepresentable {
    package init(
        text: Binding<String>,
        selection: Binding<NSRange>,
        configuration: EditorConfiguration,
        handlers: EditorHandlers
    )
}

package struct EditorConfiguration: Equatable {
    package var proseFont: NSFont
    package var codeFont: NSFont
    package var lineHeightMultiple: CGFloat
    package var colors: EditorColors          // plain NSColor values, filled by Presentation from Theme
    package var linkPatterns: [EditorLinkPattern]   // id, regex string, label template, icon name
    package var imageMaxHeight: CGFloat
}

package struct EditorHandlers {
    package var resolveImage: (String) -> URL?               // relative link → file URL, nil hides the image
    package var pasteImage: (Data, String) -> String?        // bytes, file extension → Markdown to insert
    package var pasteFiles: ([URL]) -> String?
    package var pasteURL: (URL) -> String?                   // nil → insert the plain URL
    package var openLink: (EditorLink) -> Void               // url, wiki target, pattern id + match
    package var wikilinkCompletions: (String) -> [String]
    package var tagCompletions: (String) -> [String]
    package var requestScreenshot: (ScreenshotKind) -> Void  // host runs the use case and inserts through `insert`
    package var didChange: () -> Void
}

package final class EditorCommands {        // handed back through handlers.ready(EditorCommands)
    package func insert(_ markdown: String, at: InsertionPoint)
    package func wrapSelection(prefix: String, suffix: String)
    package func toggleCheckbox()
    package func moveLine(up: Bool)
    package func duplicateLine()
    package func scroll(to range: NSRange)
    package func focus()
}
```

The editor owns the `NSTextView`, the styling, the list commands, paste classification and the rendering of images, checkboxes and chips. It never touches a file, the index or the vault. `text` is the full source; the host (EditorStore) debounces and saves.

### 6.2 Rules

- TextKit 2 only. Never read `textView.layoutManager`: that call switches the view to TextKit 1 for good (`PLAYBOOK.md` section 9).
- Styling is display-only through `NSTextContentStorageDelegate.textContentStorage(_:textParagraphWith:)`: the source text keeps plain attributes; each paragraph gets its display attributes when it is laid out. Fence state (inside a code block or not, and its language) comes from `FenceTracker`, a line-state cache updated in `textStorage(_:didProcessEditing:range:changeInLength:)` for the edited lines and every line after a fence change.
- Images and checkboxes draw in `NSTextLayoutFragment` subclasses supplied by `NSTextLayoutManagerDelegate.textLayoutManager(_:textLayoutFragmentFor:in:)`: an image line gets extra height and draws the image below the text; a checkbox line draws the glyph over the `[ ]` characters. Hit testing goes through `textLayoutManager.textLayoutFragment(for:)` and the fragment's own bounds. Apple's WWDC21 "Meet TextKit 2" sample has the shape of this code.
- `CodeHighlighter` is a regex pass per language over one paragraph plus the fence language. No JavaScript, no external highlighter.
- A keystroke restyles only the edited paragraphs and, after a fence change, the paragraphs below until the next fence state agrees with the cache. Measure with the 5,000-line fixture in `SlateEditorTests/Fixtures/`.
- Paste: `PasteClassifier` is a pure function over the pasteboard content types and text; `PasteHandler` calls the matching host handler and inserts the returned Markdown. `⌘⇧V` forces code.
- Previews: `MarkdownEditorView` has a `#Preview` with a long fixture; every rendering piece has one too.

---

## 7. Presentation

### 7.1 Stores (`@Observable final class <Name>Store`, MainActor)

| Store | Owns | Gets in `init` |
|---|---|---|
| `VaultStore` | vault URL, spaces, config, index progress, cloud summary, doctor results | ports (config, index, cloud, history), `ReindexVaultUseCase`, `VaultChangeFeed`, `AppEvents`, `ActivityLog`, `KeyValueStore` |
| `NoteListStore` | selected space or view, summaries, sort, filter text, selection, pinned, move, trash | index, use cases (move, trash, restore, create), `Navigator`, `AppEvents` |
| `EditorStore` | open document, `text`, `selection`, dirty flag, autosave task, conflict state, header edits, title commit, attachment import, link resolution | files, index, journal, use cases (save, rename, attach, import, toggleTodo), `Clock`, `AppEvents`, `ActivityLog` |
| `SearchStore` | query text, parsed query, results, highlighted ranges, palette mode | index, `SearchQueryParser`, config (views), `AppEvents` |
| `CaptureStore` | draft text, target space, type, saving | `QuickCaptureUseCase`, config, `AppEvents` |
| `TodoStore` (P1) | open todos grouped | index, `ToggleTodoUseCase`, `AppEvents` |
| `DailyStore` (P1) | today, previous and next | `EnsureDailyNoteUseCase`, index, `Clock` |
| `HistoryStore` (P1) | snapshots of the open note, restore | history, `RestoreVersionUseCase` |
| `SettingsStore` | every preference, tracker settings, hotkeys names | `KeyValueStore`, `SecretStore`, config |

Rules as DevHub: a store never holds another feature's concrete store (lookup protocols in `Shared/`), never imports SwiftUI, never reads `UserDefaults`, never runs a command. `RefreshTask` for refreshes (latest wins). Every failure goes to `ActivityLog`. One `EditorStore` per editor surface (panel, each window, each floating note); two surfaces on the same note stay consistent through `noteSaved` events and the own-writes filter.

### 7.2 Events

`AppEvent`: `vaultChanged([VaultPath])`, `indexUpdated`, `noteCreated(NoteID)`, `noteSaved(NoteID, ContentHash)`, `noteRenamed(from: VaultPath, to: VaultPath)`, `noteMoved(NoteID)`, `noteTrashed(NoteID)`, `noteRestored(NoteID)`, `spacesChanged`, `configChanged(ConfigKind)`, `conflictDetected(NoteID)`, `settingsChanged`, `captureSaved(NoteID)`, `snapshotTaken`. Subscribe in `init`, keep the `SubscriptionToken`. A store ignores the echo of its own post. Add a case only when a second store needs to react.

`VaultChangeFeed` (Shared) is the one consumer of `VaultWatching.changes()`: it runs the incremental reindex through `ReindexVaultUseCase` and posts `vaultChanged` and `indexUpdated`.

### 7.3 Rows, mappers, views

As DevHub: `<Row>Model` is a plain struct with display strings, `Tint`, icon names and flags, plus `static let preview`; `<Row>Mapper` is a pure `static func model(for:)`; one view per file; a row takes a model and closures; every row and screen has a `#Preview`.

### 7.4 Windows

`AppWindows` owns: the status item, the panel (`NSPanel` per `PLAYBOOK.md` section 1), the main windows (`NSWindow`, autosave frame name per window index), the capture panel (non-activating `NSPanel`, `PLAYBOOK.md` section 2), floating note windows (P1). All host `RootView().inject(assembly)` with an environment `Surface` value (`.panel`, `.window`, `.capture`, `.floating(NoteID)`).

### 7.5 Theme

`Theme` tokens map to system colours: `base` (`windowBackgroundColor`), `surface` (`controlBackgroundColor`), `border` (`separatorColor`), `text` (`labelColor`), `secondaryText`, `selection` (accent), `codeBackground` (`quaternaryLabelColor` at low alpha), `chip` tints. No hex values outside `Theme`. Both appearances are checked in previews with `.preferredColorScheme`.

---

## 8. Composition

| Piece | Module | Does |
|---|---|---|
| `Ports` | Domain | struct of every port |
| `Ports.live(vault:appSupport:shell:recorder:)` | Data | builds every live implementation once (M0: `Ports.live(pending:)`, section 4.3) |
| `Ports.mock()` | Mocks | in-memory everything, `MockVault` sample |
| `UseCases(ports:)` | Domain | builds every use case |
| `PresentationAssembly(ports:useCases:kv:…)` | Presentation | builds shared objects and stores in dependency order |
| `PresentationAssembly.preview()` | Presentation | mocks for previews |
| `AppWindows(assembly:)` | Presentation | windows and panels |
| `AppContainer.live()` | Composition | reads the vault URL from `UserDefaults` (first launch: picks the default, runs `VaultBootstrap`), builds `ShellRunner`, `Ports.live`, `UseCases`, `PresentationAssembly`, `AppWindows`, registers hotkeys (`KeyboardShortcuts`), `ServicesProvider`, `LoginItem`; exposes `handle(urls:)` and `flush()` |
| `URLCommandParser` | Composition | `URL` → `URLCommand` enum (`new`, `open`, `append`, `capture`, `search`); rejects anything else |
| `URLCommandHandler` | Composition | `URLCommand` → use case call and `AppActions` navigation |
| `ServicesProvider` | Composition | `@objc addToSlate(_:userData:error:)` → `QuickCaptureUseCase` |
| `CLIContainer` | SlateCLI | `Ports.live` with a `NoopRecorder`, the handful of use cases the commands need; opens the app through `open "slate://…"` when asked |

---

## 9. Data flows

### 9.1 Open the panel
Status item click → `AppWindows.togglePanel()` → frame from `WindowLayout`, `makeKeyAndOrderFront` → `RootView` `.task(id: openCount)` → `NoteListStore.refresh()` reads `SearchIndex.summaries` (fast, no file reads) → `EditorStore` keeps the last note.

### 9.2 Create a note
`⌘N` → `NoteListStore.createNote(type:)` → `CreateNoteUseCase` (config defaults, template, unique stem, `VaultFileStore.write`, `SearchIndex.upsert`) → event `noteCreated` → `Navigator.select(id)` → `EditorStore.open(id)` reads the file, keeps `loadedHash`, places the caret.

### 9.3 Type and save
Editor `didChange` → `EditorStore.text` changed → journal write (throttled 1 s) → autosave task 500 ms → `SaveNoteUseCase.run(document, expected: loadedHash)` → `.saved(hash)`: `loadedHash = hash`, `noteSaved` → `NoteListStore` updates the row from the index. `.conflict`: `conflictState = .diskChanged`, banner.

### 9.4 External change
FSEvents → `ChangeCoalescer` (300 ms) → `VaultChangeFeed` → own-writes filter → `ReindexVaultUseCase.run(paths)` → `indexUpdated`, `vaultChanged(paths)` → `EditorStore` for an open path: `ConflictPolicy.decide` → reload (not dirty) or banner (dirty). `NoteListStore` refreshes.

### 9.5 Rename
Title commit → `RenameNoteUseCase` → move file, rewrite linking files, index → `noteRenamed` → every `EditorStore` on a rewritten file reloads when not dirty, else banner.

### 9.6 Quick capture
Hotkey → capture panel (non-activating) → Enter → `CaptureStore.save()` → `QuickCaptureUseCase` → `captureSaved` → panel closes, toast in the main panel next time it opens.

### 9.7 Search
Keystroke → `SearchStore` debounce 80 ms → title matches from the in-memory summaries at once → `SearchIndex.search(query)` on a background task → merge, dedupe, rank.

### 9.8 CLI append
`slate append --ticket ABC-123 --section Findings "…"` → `CLIContainer` → `AppendToNoteUseCase` → writes the file and upserts the index (SQLite WAL allows the app to read at the same time) → the app's watcher sees the change → `EditorStore` reloads when not dirty.

---

## 10. Extension points

| To add | Touch |
|---|---|
| A note type | a `.slate/types/<type>.json` and `_templates/<type>.md` in the vault. No code |
| A link pattern | `.slate/links.json`. No code |
| A smart view | `.slate/views.json`. No code |
| An action | `.slate/actions/<name>.json` plus a script. No code |
| A template placeholder | `TemplateRenderer` and its test |
| A search filter | `SearchQueryParser`, the `WHERE` builder in `GRDBSearchIndex`, tests |
| A header field | `NoteHeader`, `FrontmatterParser` and `Writer` known keys (order list), the index column and `IndexedNoteBuilder`, `NoteHeaderView`, a schema version bump, an ADR when it changes the on-disk contract |
| A paste kind | `PasteKindPolicy`, `PasteHandler`, a handler closure |
| A code language | one file in `SlateEditor/Highlighting/languages/` and a fixture test |
| A new source of data (another tracker, a web clipper) | a port in Domain, a live type in Data, a mock, a spy, a use case when two ports meet, a store or an action |
| A CLI command | one file in `SlateCLI`, reuse a use case; never new file logic in the CLI |
| A URL route | `URLCommandParser`, `URLCommandHandler`, tests |
| A screen | `/add-feature` skill (copied from DevHub): store, models, views, assembly line, tests |

---

## 11. Concurrency

- Domain, Data, Mocks, TestSupport, CLI are nonisolated by module default. UI, Editor, Presentation, Composition are MainActor by default.
- File and index work runs in `async` port methods off the main actor; `GRDBSearchIndex` uses a `DatabasePool` with WAL; reads and writes go through GRDB's own queues.
- `ShellRunner` is an `actor`. Git snapshots, `screencapture` and actions run there and never block typing.
- Every `Task` started by a store is stored and cancelled when the store's surface closes. No fire-and-forget tasks in stores except `ActivityLog` writes.
- No `DispatchQueue` outside `ShellRunner` (pipe reads) and `ChangeCoalescer` (FSEvents callback queue). No `nonisolated(unsafe)`.

---

## 12. Tests

Swift Testing in five test targets. `Scripts/test.sh` runs `swift test -q` on the package and prints one summary line.

Must exist by the end of the milestone that introduces the type (`ROADMAP.md`):

- Domain: `FrontmatterParserTests` (round trip, unknown keys kept, opaque header, quoting rules), `NoteCodecTests`, `StemPolicyTests`, `SlugPolicyTests`, `TitlePolicyTests`, `WikilinkPolicyTests`, `TodoLinePolicyTests`, `SectionAppendPolicyTests`, `DailyPolicyTests`, `TemplateRendererTests`, `SearchQueryParserTests`, `ConflictPolicyTests`, `PasteKindPolicyTests`, `LinkPatternPolicyTests`, `PreviewPolicyTests`, `SlackFormatPolicyTests`, one test per use case over spies.
- Data: `FileVaultStoreTests` (temp folder; atomic write, expected hash conflict, move), `GRDBSearchIndexTests` (in-memory database; upsert, search, filters, rank, snippet), `FTSMatchBuilderTests` (quotes, dashes, colons never reach FTS raw), `IndexedNoteBuilderTests`, `FileTrashRepositoryTests`, `FileTemplateRepositoryTests`, `FileVaultConfigRepositoryTests`, `ChangeCoalescerTests`, `GitLogParserTests`, `GitHistoryRepositoryIntegrationTests` (real `git`, tagged `.integration`), `ScreencaptureToolTests` (argument building only).
- Editor: `MarkdownLineScannerTests`, `FenceTrackerTests` (fence open, close, nested backticks, edit above a fence), `CodeHighlighterTests` per language, `ListEditingTests`, `CheckboxToggleTests`, `PasteClassifierTests`, a performance test that restyles after an edit in the 5,000-line fixture under 16 ms.
- Presentation: mapper tests, store tests over spies (`NoteListStore`, `EditorStore` autosave and conflict paths, `SearchStore` merge, `CaptureStore`), `URLCommandParserTests` lives in a Composition test file inside `SlatePresentationTests` only if Composition gets no own target; prefer a sixth target `SlateCompositionTests` when it has more than two suites.
- Conventions: `@Suite struct <Type>Tests`, folders mirror `Sources/`, `@testable import`, fixtures in `Fixtures/`, files only through `TemporaryDirectory`, no `Task.sleep`, `waitUntil` for background work, never assert on locale or clock text.

---

## 13. Scripts and lint

| Script | Does |
|---|---|
| `Scripts/build.sh [Debug\|Release]` | `check-layers.sh`, then `xcodebuild -quiet` into `DerivedData/`; prints `layers: ok` and the `.app` path |
| `Scripts/test.sh [--skip integration] [--filter Suite]` | `swift test -q` in the package |
| `Scripts/run.sh` | Debug build, `pkill -x Slate`, open |
| `Scripts/install.sh` | Release build to `/Applications/Slate.app`, the `slate` CLI to `~/.local/bin/slate` |
| `Scripts/generate-vault.sh <folder> <count>` | writes `<count>` sample notes with headers, tags, todos, code and images for performance checks |
| `Scripts/check-layers.sh` | the rules below |

`check-layers.sh` checks what the compiler cannot:

- `SlateDomain` imports only `Foundation` (and `CryptoKit` for the hash).
- `SlateData`: no `SwiftUI`; `AppKit` only under `System/`; `Process` only in `Shell/ShellRunner.swift`; `NSFileCoordinator` only under `Files/`; `UserDefaults` only in `Persistence/UserDefaultsKeyValueStore.swift`; `import GRDB` only under `Index/`; `import Markdown` only under `Index/` and `Export/`.
- `SlateEditor`: no import of any package module; `NSPasteboard` only under `Paste/`; no `layoutManager` token anywhere.
- `SlatePresentation`: no `GRDB`, no `FileManager` writes, no `Process`, no `NSPasteboard` outside `Shared/PasteboardWriter.swift`; `import SlateMocks` only in `PresentationAssembly+Preview.swift`.
- Everywhere: no `.shared` except Apple singletons listed in `layer-exceptions.txt`, no comment lines (`//` not followed by `MARK`), one top-level type per file, no hex colours outside `Theme.swift`.

---

## 14. Dependencies

| Package | Used for | Where |
|---|---|---|
| `GRDB.swift` | SQLite, FTS5, WAL pool | `SlateData/Index/` |
| `swift-markdown` | parsing bodies for the index, outline, export | `SlateData/Index/`, `SlateData/Export/` |
| `KeyboardShortcuts` | global hotkeys with a recorder view in Settings, no Accessibility permission | `SlatePresentation` (recorder view), `SlateComposition` (registration) |
| `swift-argument-parser` | the CLI | `SlateCLI` |

Not used, on purpose: SwiftData and Core Data (files are the store), CloudKit (needs a developer account), `highlight.js` or any JavaScript engine (start time), `STTextView` (dual licence, and `NSTextView` on TextKit 2 is enough), a YAML library (the header is a flat subset).
