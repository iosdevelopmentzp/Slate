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
| `SlateEditor` | swift-markdown (under `Markdown/` only) | MainActor | the rich text view on TextKit 2, the Markdown reader and writer, format commands, list behaviour, image blocks (section 6, ADR 0008) |
| `SlatePresentation` | Domain, UI, Editor, Mocks, KeyboardShortcuts | MainActor | stores, row models and mappers, views, events, `PresentationAssembly`, `AppWindows` |
| `SlateComposition` | Domain, Data, Mocks, Presentation | MainActor | `AppContainer` (the only `public` type), URL scheme handling, Services provider, launch at login |
| `SlateTestSupport` | Domain | nonisolated | `Spy<Port>` for every port, `TemporaryDirectory`, `waitUntil`, fixtures |
| `slate` (executable, target `SlateCLI`) | Domain, Data, swift-argument-parser, MCP (`modelcontextprotocol/swift-sdk`) | nonisolated | the command line tool and `slate mcp`, the MCP server for agents (ADR 0010) |

- `SlatePresentation` imports `SlateMocks` in one file only: `Shared/PresentationAssembly+Preview.swift`.
- `SlateEditor` imports AppKit, SwiftUI, Foundation, Observation and, only under `Markdown/`, the `Markdown` product of swift-markdown. It knows nothing about notes, vaults or the index. This keeps the riskiest code replaceable.
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
        .target(name: "SlateEditor", dependencies: [.product(name: "Markdown", package: "swift-markdown")], swiftSettings: mainActor),
        .target(name: "SlatePresentation", dependencies: [
            "SlateDomain", "SlateUI", "SlateEditor", "SlateMocks",
            .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
        ], swiftSettings: mainActor),
        .target(name: "SlateComposition", dependencies: ["SlateDomain", "SlateData", "SlateMocks", "SlatePresentation"], swiftSettings: mainActor),
        .target(name: "SlateTestSupport", dependencies: ["SlateDomain"], swiftSettings: shared),
        .executableTarget(name: "SlateCLI", dependencies: [
            "SlateDomain", "SlateData",
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "MCP", package: "swift-sdk"),
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
  SlateApp.swift                 @main, Settings { EmptyView() }, @NSApplicationDelegateAdaptor(AppContainer.self)
Config/Slate-Info.plist          CFBundleURLTypes (slate) and NSServices (Add to Slate); merged with the generated Info.plist
  Assets.xcassets
  Slate.entitlements             empty
Packages/SlateKit/
  Package.swift
  Sources/
    SlateDomain/
      Models/                    Note, NoteDocument, NoteSummary, NoteHeader, NoteType, Space, Tag, TodoItem, Attachment, Link, SearchHit, Snapshot, TrashItem, CloudStatus, ConflictVersion, ActionDefinition, LinkPattern, SmartView, IssueDetails
      Values/                    NoteID, VaultPath, SpaceName, FolderPath, Stem, ContentHash, TicketKey, BranchName
      Ports/                     one protocol per file (section 4.3)
      Policies/                  pure functions (section 4.4)
      Codec/                     NoteCodec, FrontmatterParser, FrontmatterWriter
      UseCases/                  one struct per file (section 4.5)
      Errors/                    SlateError and friends, LocalizedError
      Assembly/                  Ports, UseCases(ports:)
    SlateData/
      Files/                     FileVaultStore, FileCoordination (coordinated read, write, move, atomic replace), OwnWrites, VaultFolder, JSONFile, FileAttachmentStore, FileTrashRepository, FileTemplateRepository, FileVaultConfigRepository, FileJournalStore, VaultBootstrap
      Index/                     GRDBSearchIndex, IndexSchema, SearchSQL, IndexedNoteBuilder (swift-markdown), FTSMatchBuilder
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
    SlateUI/                     Theme, Tint, Tint+Color, SoftPill, RoundButton, ColorDot, AccentButtonStyle, EmptyStateView, ToastView, SearchField, IconButton, RowContainer, ListState, InlineConfirmation, OverflowMenu, Tag, Formatters/, Hint/, CopyOnClick
    SlateEditor/
      RichTextEditorView.swift   NSViewRepresentable, the entry point for the host
      EditorConfiguration.swift  text size, colours, image height limit as plain values
      EditorHandlers.swift       closures the host supplies (section 6.1)
      EditorCommands.swift       observable command sink and style state for the format bar (EditorCommand, EditorStyleState)
      EditorMenuActions.swift    selectors of the Format menu
      Model/                     BlockKind, BlockAttributes, InlineStyle, RichText, NSAttributedString+RichText (the slate.* keys)
      Markdown/                  MarkdownReader, MarkdownWriter, ListReader, ListWriter, InlineReader, InlineWriter, WikilinkScanner, SourceLines (swift-markdown allowed here only)
      Core/                      RichTextController (+Editing, +Commands, +Delegates, +Link, +Mouse), RichTextView (NSTextView subclass), LinkPopover
      Commands/                  KeyboardMap
      Styling/                   RichTextStyler, RichLayoutFragment, ParagraphDecoration, ImageAttachment, DividerAttachment
      Paste/                     PasteboardReader, HTMLImport, RichTextController+Paste (NSPasteboard allowed here)
    SlatePresentation/
      Shared/                    Surface, ListSource, Navigator, ActivityLog, ActivityRecorder (CommandRecording → ActivityLog), Toaster (+ ToastAction for Undo), PasteboardWriter, WindowLayout, TextFocus, NoteDragPayload, RefreshTask, VaultChangeFeed, NoteLookup, PresentationAssembly (+Preview), View+Inject, View+PreviewEnvironment
      Shared/Events/             AppEvent, AppEvents, SubscriptionToken
      Shell/                     AppWindows (status item, panel, window, capture panel), MenuBarPanel, CapturePanel, MainMenuBuilder, MenuTarget, FirstLaunchWindow, FirstLaunchView, RootView, SidebarView, ColumnResizer, drag and resize
      Features/Vault/            VaultStore, Models/ (FolderRowModel, FolderRowMapper, FolderTreeMapper, FolderNode, FolderEdit, FolderIcon, FolderTint), Views/ (FolderRow, FolderNameField, FolderMenu, FolderDeleteConfirmation)
      Features/NoteList/         NoteListStore, Models/ (NoteRowModel, NoteRowMapper, NoteRowActions, TrashRowModel, TrashRowMapper), Views/ (NoteListColumn, NoteListView, NoteCard, NoteRowMenu, TrashListView, TrashRow)
      Features/Editor/           EditorStore (+Attachments, +Journal), Models/ (SaveState, BodyFocus, MarkdownInsertion, FormatBarMapper, FormatButtonModel, FormatStyleModel), Views/ (EditorView, FormatBar, FormatButton, ConflictBanner, RecoveryBanner)
      Features/Search/           SearchStore, Models/ (SearchResultRowModel, SearchResultMapper), Views/ (SearchResultsView, SearchResultRow)
      Features/Capture/          CaptureStore, Views/ (CaptureView, CaptureTextView)
      Features/History/          HistoryStore, Views/
      Features/Settings/         SettingsStore, Views/ (SettingsView, GeneralSettingsView with Check-up, ShortcutSettingsView)
      Features/Activity/         ActivityView
    SlateComposition/            AppContainer, URLCommandParser, URLCommandHandler, ServicesProvider, LoginItem
    SlateTestSupport/            Spy<Port> per port, PortSpies, Ports+Spies, TemporaryDirectory, WaitUntil, TestError, VaultFixture (writes a sample vault into a temporary folder)
    SlateCLI/                    SlateCommand (root), New, Open, Append, Today, Search, List, Path, MCP, CLIContainer;
                                 MCPServerFactory, MCPToolCatalog (the eleven tools), MCPToolRunner (+Read, +Write), MCPArguments
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

- `package` on every type and member another module uses, including `package init`, `package var body`, `package static let`. Internal for what one module uses alone. `public` only on `AppContainer`, its `init()` and its `NSApplicationDelegate` methods; the CLI target is an executable and needs no `public`.
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
| `VaultChange` | enum: `.paths(Set<VaultPath>)` for changed, new or removed notes, `.rescan` for folder, config and template changes. The reindex reads the disk for each path, so the kind of change is not needed |
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
| `VaultFileStore` | `enumerate() -> [FileMeta]`, `read(VaultPath) -> FileContents` (bytes, hash, meta), `meta(VaultPath) -> FileMeta?`, `write(VaultPath, data:, expected: ContentHash?) -> WriteResult` (`.written(hash)`, `.conflict(diskHash:)`), `create(VaultPath, data:) -> ContentHash` (fails when the file exists), `move(from:to:)`, `fileNames(inFolder:)`, `folders() -> [FolderPath]` (every sub-folder below the top-level folders, not `_` or hidden ones), `createFolder(FolderPath)`, `moveFolder(from:to:)`, `removeFolder(FolderPath)` (removes an empty folder, moves a folder with other files to the macOS Trash) | `FileVaultStore` (an actor) |
| `SearchIndex` | `summaries(space:)`, `summary(id:)`, `fileStates() -> [VaultPath: IndexedFileState]`, `upsert(IndexedNote)`, `upsert(contentsOf:)`, `updateState(_:for:)`, `remove(path:)`, `search(SearchQuery, limit:) -> [SearchHit]`, `notes(named:)`, `notes(withTicket:)`, `notesLinking(to:)`, `tags() -> [TagCount]`, `todos(isDone:)`, `reset()` | `GRDBSearchIndex` (M3; `MemorySearchIndex` was removed). The spy and the mock answer `search` with `SearchMatchPolicy` |
| `IndexedNoteBuilding` | `build(NoteDocument) -> IndexedNote` (the document carries its meta and hash; uses swift-markdown) | `IndexedNoteBuilder` |
| `VaultWatching` | `changes() -> AsyncStream<VaultChange>` | `FSEventsVaultWatcher` |
| `AttachmentStore` | M2: `fileNames()`, `write(Data, named:)` and `copy(URL, named:)` (both fail when the name exists), `size(of:)`, `externalSize(URL)`, `url(for:)`. Naming and links are `AttachmentPolicy`; the use cases pick the name. M5 adds `moveToTrash(file)` | `FileAttachmentStore` |
| `TrashRepository` | `trash(VaultPath, at: Date) -> TrashItem`, `restore(TrashItem) -> VaultPath`, `items()`, `delete(TrashItem)` (M5: to the macOS Trash with `FileManager.trashItem`; the use case picks the items) | `FileTrashRepository` |
| `TemplateRepository` | `body(for: String) -> String` (type name; a missing file falls back to `BuiltInTemplates`), `ensureDefaults()` | `FileTemplateRepository` |
| `VaultConfigRepository` | S5 adds `agentPermissions()` and `saveAgentPermissions(_:)` (`.slate/agents.json`). M1: `spaces() -> SpacesConfig` (folders on disk merged with `spaces.json`), `saveSpaces(SpacesConfig)`, `types() -> [NoteType]` (built-ins plus `.slate/types/`), `ensureDefaults()`. M4 adds `linkPatterns()`, `views()`, `actions()` and tracker settings for the defaults | `FileVaultConfigRepository` |
| `JournalStore` | `save(JournalEntry)`, `entry(for:)`, `clear(_:)`; one JSON file per note in `<support>/journal/` | `FileJournalStore` |
| `ScreenCapturing` | `capture(CaptureMode, to: URL)`; success is a file larger than zero bytes, checked by `AttachScreenshotUseCase` | `ScreencaptureTool` |
| `HistoryRepository` | `isAvailable()`, `ensureRepository()`, `snapshot(message:) -> Bool`, `history(of:) -> [Snapshot]`, `contents(of:at:) -> Data`, `push(to:)`, `lastSnapshot()` | `GitHistoryRepository` (an actor, `<support>/history.git`) |
| `CloudStatusProviding` | `status(of: VaultPath) -> CloudStatus`, `startDownload(VaultPath)`, `conflictVersions(VaultPath) -> [ConflictVersion]`, `keep(version:, for:)`, `isCloudFolder(URL) -> Bool` | `UbiquityStatusProvider` |
| `LinkTitleFetching` | `title(for: URL) -> String?` (2 s timeout) | `URLSessionLinkTitleFetcher` |
| `IssueTrackerClient` | `issue(_:) -> IssueDetails`, `currentUser()` | `JiraIssueClient` (REST v3, basic auth, 5 s) with `JiraIssueParser` |
| `SecretStore` | `secret(for:)`, `setSecret(_:for:)`, `removeSecret(for:)` | `KeychainSecretStore` (generic password, service `local.slate.app`) |
| `KeyValueStore` | `string/bool/int/data(forKey:)`, setters | `UserDefaultsKeyValueStore` |
| `Clock` | `now() -> Date`, `timeZone` | `SystemClock` |
| `ActionRunning` | `run(command, environment:, workingDirectory:) -> ActionResult`; `/bin/zsh -c`, 60 s limit | `ShellActionRunner` |
| `NoteExporting` | `html(title:body:)`, `pdf(title:body:)`, `saveToDownloads(_:fileName:)` | `NoteExporter` (System, AppKit for the PDF) over `HTMLExporter` (Export, swift-markdown) |
| `WorkspaceOpening` | `open(URL)`, `reveal(URL)`, `quickLook(URL)` | `WorkspaceOpener` |
| `CommandRecording` | `record(CommandRecord)` | `ActivityLog` conformance in Presentation |
| `AgentChangeLog` | `record(AgentChange)`, `changes(after: Date)`; written by `slate mcp`, read by the app for the Activity line "Changed by an agent" (S5) | `FileAgentChangeLog` (an actor, `<support>/agent-changes.jsonl`, the last 200 lines) |

`Ports` (Domain `Assembly/Ports.swift`) is a struct with one property per port. `Ports.live(root:keyValues:)` in Data (later milestones add the Application Support folder, the shell and the recorder), `Ports.mock()` in Mocks, `Ports.spies(keyValues:)` in TestSupport (the key-value store defaults to `SpyKeyValueStore`).

Since M7 the code has twenty ports (`actions`, `exporter` in M6; `secrets`, `tracker` in M7): `keyValues`, `files`, `index`, `builder`, `watcher`, `trash`, `templates`, `config`, `clock`, `attachments`, `capture`, `workspace`, `loginItem` (M4), `system` (M4, the Doctor checks), `history`, `journal` (M5). `Ports.live(root:support:keyValues:recorder:)` throws when the index cannot open, builds one `ShellRunner` with the recorder, and opens `index.sqlite` in the support folder (`VaultSupportFolder.url(for:)`, `~/Library/Application Support/Slate/<vault-id>/`). The spies are in-memory fakes that also record their calls, so use case and store tests run without a disk.

### 4.4 Policies (pure, `enum XPolicy { static func … }`)

| Policy | Does |
|---|---|
| `StemPolicy` | `stem(forTitle:)`, `unique(_, among:)` per `STORAGE-FORMAT.md` 3.1 |
| `SlugPolicy` | branch slug, `renderBranch(pattern:, ticket:, title:)` |
| `TitlePolicy` | `titlePattern` rendering, split `ABC-123 Title` into ticket and title using the tracker regex |
| `WikilinkPolicy` | `targets(in:)`, `parse(_:)`, `rewrite(_:from:to:)`, `resolve(_:candidates:from:)` |
| `MarkdownText` | prose lines of a body (fences skipped, line numbers kept, inline code ranges) for the line-based policies |
| `TagPolicy`, `CompletionPolicy`, `SearchMatchPolicy`, `SearchHighlightPolicy`, `IndexFactsPolicy`, `VaultIdentityPolicy` | inline and merged tags; note name and tag completion; in-memory matching and ranking for the spy, the mock and the CLI fallback; match ranges and the title score; the index facts of a note without swift-markdown; the vault id |
| `TodoLinePolicy` | `parse(line) -> TodoItem?`, `toggle(line) -> String`, `cycle(line) -> String` |
| `SectionAppendPolicy` | `append(text, toSection:, in body:) -> String` per `STORAGE-FORMAT.md` 4 |
| `DailyPolicy` | `stem(for date)`, `logLine(time, text)`, `carryOver(from previousBody) -> [String]` |
| `TemplateRenderer` | placeholders, `{{cursor}}` offset |
| `SearchQueryParser` | text → `SearchQuery` |
| `ConflictPolicy` | `decide(loadedHash, diskHash, isDirty, ownWrites) -> .ignore | .reload | .conflict` |
| `AttachmentPolicy` | attachment file names, unique names, relative links, Markdown for an image or a file, link → vault path |
| `LinkPatternPolicy` | `matches(body, patterns, excluding code ranges) -> [Link]`, `shortForm(for url, patterns)` |
| `PreviewPolicy` | strip Markdown marks, first 200 characters |
| `TrashRetentionPolicy` | which items are due for purge |
| `HeaderDefaultsPolicy` | header defaults per type and space |
| `SlackFormatPolicy` | Markdown → Slack text (F6) |
| `AgentPathPolicy` | S5: a path or folder from an agent → `VaultPath` or `FolderPath`; rejects `..`, paths outside the vault, `.` and `_` folders |
| `AgentGuide` | S5: the text of the `CLAUDE.md` / `AGENTS.md` block, its markers and the registration line |
| `ImageTypePolicy` | S5: PNG, JPEG, GIF, WebP or HEIC from the first bytes |
| `NoteLinkPolicy` | S5: `slate://open?id=<id>` for Copy Link and `open_in_slate` |

Every policy has a test file with fixtures.

### 4.5 Use cases (`struct XUseCase: Sendable`, ports as `let`, one entry point)

| Use case | Ports | Does |
|---|---|---|
| `CreateNoteUseCase` | config, templates, files, index, builder, clock | type defaults, title and ticket split, unique stem, template render, write, index, returns the document and the caret offset |
| `SaveNoteUseCase` | files, index, builder, journal, clock | encode, `updated` only when changed, coordinated write with expected hash, index upsert, journal clear; returns `.saved(hash)` or `.conflict(diskHash)` |
| `RenameNoteUseCase` | files, index, builder, save | per `STORAGE-FORMAT.md` 3.3, returns `RenameReport` (the save result, rewritten files, failures). A link is rewritten only when it resolves to the renamed note (`WikilinkPolicy.resolve`) |
| `MoveNoteUseCase` | files, index, builder | move into a folder or sub-folder, unique stem, rewrite links into `_attachments/` when the depth changes (`AttachmentPolicy.rewriteLinks`), index update |
| `DeleteSpaceUseCase` | files, config, move | refuses the quick note folder; moves every note of the folder to the quick note folder, removes the folder and its entry; returns a `SpaceDeletion` for Undo |
| `RestoreSpaceUseCase` | files, config, move | Undo of a deletion: the folder and its entry come back at the same place, notes that are still where the deletion put them move back (through `MoveNoteUseCase`, so image links follow) |
| `CreateFolderUseCase` | files | a sub-folder inside a folder; the name follows `SpaceNamePolicy`, unique among its siblings (ADR 0011) |
| `RenameFolderUseCase` | files, reindex | renames a sub-folder (not a top-level folder), even by case only, then reindexes |
| `DeleteFolderUseCase` | files, move | moves every note in the sub-folder and below to its parent, removes the folder; returns a `FolderDeletion` for Undo |
| `RestoreFolderUseCase` | files, move | Undo: makes the folders again and moves the notes back to their old paths |
| `OpenTargetUseCase` | index, create | `slate://open` by id, title or ticket; `.found`, `.created` (a ticket without a note) or `.missing` |
| `TrashNoteUseCase`, `RestoreNoteUseCase`, `PurgeTrashUseCase` | trash, index, clock | |
| `QuickCaptureUseCase` | create, append (as nested use cases) | capture input → new note or Today line |
| `EnsureDailyNoteUseCase` | index, files, create, clock | today's note, carry-over block |
| `AppendToNoteUseCase` | index, files, builder, ensureDaily, clock | target by `today`, `ticket`, `id` or `path`; creates a task note for an unknown ticket; section append |
| `AttachScreenshotUseCase` | capture, attachments, clock | temp file → attachment → Markdown to insert, `nil` when cancelled |
| `ImportAttachmentUseCase` | attachments | data or file → Markdown |
| `ReindexVaultUseCase` | files, index, builder, cloud | full or paths; compare `(mtime, size)` then hash; reports progress through an `AsyncStream<IndexProgress>` |
| `ToggleTodoUseCase` | files, index, builder | edit one line in a file by number, coordinated |
| `SnapshotHistoryUseCase` | history, clock, kv | throttle, snapshot when dirty, optional push, an optional message (`agent: <tool> <title>`) |
| `AgentGuideWriter` | files | S5: writes the agent block into `CLAUDE.md` and `AGENTS.md`, keeps the text outside the markers, writes only on a change |
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

## 6. The editor module (revision 2, ADR 0008)

### 6.1 Contract

```swift
package struct RichTextEditorView: NSViewRepresentable {
    package init(
        markdown: Binding<String>,              // the note body; the editor reads it and writes it back
        configuration: EditorConfiguration,     // text size (base 15), colours, image height limit
        commands: EditorCommands,               // shared with the format bar
        focus: EditorFocusRequest? = nil,       // token, at the start or at the first of some words
        insertion: EditorInsertion? = nil,      // token and Markdown blocks to insert at the caret
        handlers: EditorHandlers = EditorHandlers()
    )
}

package enum MarkdownReader { static func read(_ markdown: String) -> NSMutableAttributedString }
package enum MarkdownWriter { static func write(_ text: NSAttributedString) -> String }

package struct EditorHandlers {
    var didEndEditing: () -> Void
    var resolveImage: (String) -> URL?             // relative link → file URL
    var openLink: (EditorLink) -> Void              // .url(String) or .wiki(String)
    var attachment: (String, AttachmentAction) -> Void   // Quick Look, open, reveal, copy image
    var pasteImage: (Data, String) -> Void          // bytes, extension; the host inserts the link
    var pasteFiles: ([URL]) -> Void
    var requestScreenshot: (ScreenshotKind) -> Void
}

@Observable package final class EditorCommands {
    package internal(set) var state: EditorStyleState   // paragraph kind, inline flags, link, canFormatText
    package func perform(_ command: EditorCommand)       // style, list, quote, inline, link, image, divider, screenshot, indent
    package func flush()                                  // writes pending Markdown into the binding now
    package func focus()
}
```

`EditorMenuActions` holds the selectors of the Format menu; `RichTextView` answers them.

### 6.2 Rules

- TextKit 2 only; never read `textView.layoutManager`. Rich text mode (`isRichText = true`), no font panel, no automatic substitutions, undo on.
- The model: one paragraph per block, separated by `\n`. A line break inside a block (a soft break, a line of code or of a raw block) is U+2028. Images and dividers are one U+FFFC character with an attachment. The `slate.*` attributes are the single truth: `slate.block`, `slate.indent`, `slate.done`, `slate.language`, `slate.imagePath`, `slate.imageAlt`, `slate.group` (which list or quote a paragraph belongs to), `slate.inline` (bold, italic, strikethrough, code as bits), `slate.href` (`wiki:` prefix for a wikilink), `slate.hardBreak`, `slate.listNumber`.
- `SlateEditor/Markdown/` holds the reader and the writer, both pure. The reader uses swift-markdown with `.disableSmartOpts`; anything outside `STORAGE-FORMAT.md` section 11 becomes a raw block sliced from the source. `write(read(x)) == x` for files Slate wrote; the tests run a fixture set and random documents.
- The storage holds the real fonts. `RichTextStyler` derives fonts, paragraph styles and attachments from the `slate.*` attributes; after an edit the controller restyles the edited paragraphs and the list around them (numbers in one pass).
- Commands go through `replace(_:with:selection:)`: `shouldChangeText`, `replaceCharacters`, `didChangeText`, so undo works. The editor has its own `UndoManager`.
- `RichLayoutFragment` draws the bullet, the number, the round checkbox, the quote bar and the code and raw backgrounds. A click on a checkbox toggles `slate.done`.
- `publish()` writes the whole document. Up to 12,000 characters it writes at once; above that it waits 250 ms after the last edit. `flush()` (called when editing ends and before the store saves or switches notes) writes at once.
- Performance: the 5,000-line fixture opens in about 120 ms and types at about 1.3 ms per key in a debug test build (`RichTextPerformanceTests`, limit 16 ms).

### 6.3 Tables (S6, ADR 0009)

- A table is one paragraph that holds one U+FFFC with `slate.block = table` and `slate.table`, a `TableBlock` (`TableModel` plus the source lines as read). `MarkdownWriter` writes the source back when the model still equals what the source parses to, and `TableMarkdown.render` otherwise.
- `SlateEditor/Tables/`: `TableModel`, `TableColumn`, `TableCell` (inline Markdown of the cell), `TableCellIndex` (row 0 is the header), `TableMarkdown` (parse and render with `\|`), `TableLayout` (column widths from the content, at least 60 pt, shrink to the text width; row heights from wrapped text), `TableStyle`, `TableAttachment`, `TableViewProvider`, `TableBlockView`, `TableCellEditor`, `TableMenu`, `TableHost`, `TableSeparatedText`. `Markdown/TableCellText` turns cell Markdown into `slate.inline` text and back.
- `SlateEditor/Find/`: the editor has its own `NSTextFinder` (the text view's `usesFindBar` is off). `NoteFindClient` gives the finder the note as pieces: the text between tables and one piece per non-empty cell, each piece ends with a search boundary (`FindSegments`). The finder reads the pieces on a background queue, so the client keeps a copy under a `Mutex`, rebuilt on the main actor after each edit while the find bar is open and before each find action. `TextSegmentRects` gives the match rectangles: TextKit 2 segments of the text view, or of a cell's text laid out in the cell's text rectangle.
- The styler gives each table paragraph a `TableAttachment`. TextKit 2 hosts its `TableBlockView` through `TableViewProvider`, registered for the file type of tab-separated text. The view draws the grid and the cells; a click puts a `TableCellEditor` (a small TextKit 2 text view) over the cell.
- The model lives in the storage attribute. While a cell is being typed the attachment keeps a live model; a commit (moving to another cell, leaving, a structure change, `flush()`, or 2 s after the last key) replaces the attachment character through `replace`, so each commit is one step of the document's undo. ⌘Z inside a cell first undoes the typing in the cell, then the document.
- Images in cells (S7): `InlineReader` reads an inline image and a `<br>` line break (ADR 0012) only when asked (`inCell`, used by `TableCellText`) as one U+FFFC with `slate.imagePath` and `slate.imageAlt`; `InlineWriter` writes it back as `![alt](path)`. `TableAttachment.display` puts a `CellImageAttachment` thumbnail (80 pt high) on that character. An import for a cell (Image button, screenshot, paste, drop) sets `RichTextController.imageTarget`; the next `EditorInsertion` goes into that cell instead of the text (`insertIntoCell`).
- `RichTextController+Tables` is the `TableHost`: commit, re-layout of the attachment range, leaving the table, delete, the active table for `flush()` and for the format commands (bold, italic, strikethrough and link go to the cell).

## 7. Presentation

### 7.1 Stores (`@Observable final class <Name>Store`, MainActor)

| Store | Owns | Gets in `init` |
|---|---|---|
| `VaultStore` | The folders: create, inline rename, delete with inline confirmation and Undo, reorder, colour and icon (S2); sub-folders: the list from disk, the open state of the tree (saved), create inside, rename, delete with Undo (ADR 0011). Holds the editing and confirmation state of the sidebar | config, files, the space and folder use cases, `KeyValueStore`, `Navigator`, `Toaster`, `ActivityLog`, `AppEvents` |
| `NoteListStore` | summaries, trash items, filter text, the trash confirmation; create, pin, move with Undo, duplicate, trash with Undo, restore. The list source (all, a space, the Trash) and the selection live in `Navigator` | index, trash, use cases (create, updateHeader, move, archive, duplicate, trash, restore), `Navigator`, `Toaster`, `ActivityLog`, `AppEvents`, `KeyValueStore` |
| `EditorStore` | open document, `text`, `title`, dirty flag, autosave (500 ms) and title commit (Enter, focus loss, 1.5 s), the title that follows the first body line for a new untitled note, focus requests, conflict state with Keep mine and Take theirs, `pendingSave()` for quit. M2 and later: selection, attachment import, link resolution, journal | files, index, use cases (save, rename), `Navigator`, `Clock`, `AppEvents`, `ActivityLog` |
| `SearchStore` | M3: query text, parsed query, results (title matches at once, the index after 80 ms), the folder scope | index, `NoteLookup` (the `NoteListStore`), `Navigator`, `Clock`, `ActivityLog`, `AppEvents` |
| `CaptureStore` | draft text, target folder, saving; Services → Add to Slate | `QuickCaptureUseCase`, `Navigator`, `Toaster`, `ActivityLog`, `AppEvents` |
| `HistoryStore` | M5: the history settings, the snapshot loop (every N minutes), the daily Trash purge, the versions of the open note, restore, the quit job, the last snapshot time and the push state; S4: the "Back up to" address (`setRemote`) and "Back up now" (`backUpNow`) | history, `SnapshotHistoryUseCase`, `RestoreVersionUseCase`, `PurgeTrashUseCase`, `KeyValueStore`, `ActivityLog`, `Toaster`, `AppEvents` |
| `SettingsStore` | text size, appearance, Trash days, the login item, the Check-up and Rebuild search | `KeyValueStore`, config, the login item and system ports, index, `ReindexVaultUseCase`, history |

Rules as DevHub: a store never holds another feature's concrete store (lookup protocols in `Shared/`), never imports SwiftUI, never reads `UserDefaults`, never runs a command. `RefreshTask` for refreshes (latest wins). Every failure goes to `ActivityLog`. One `EditorStore` per editor surface (panel, each window, each floating note); two surfaces on the same note stay consistent through `noteSaved` events and the own-writes filter. In v1 the panel and the window share one `EditorStore` (only one of them is open at a time); note windows left with ADR 0007.

### 7.2 Events

`AppEvent` since M1: `indexUpdated`, `spacesChanged`, `vaultChanged(Set<VaultPath>)` (an external edit, a header edit from the list, or links rewritten by a rename), `vaultRescanned`, `noteCreated(NoteID, caret:)`, `noteSaved(NoteID)`, `noteMoved(from:to:)` (move and rename), `noteTrashed(VaultPath)`. M3: `searchOpened(NoteID, words:)` (the editor puts the caret on the first match). Planned: `configChanged(ConfigKind)`, `settingsChanged`, `captureSaved(NoteID)`, `snapshotTaken`. Subscribe in `init`, keep the `SubscriptionToken`. A store ignores the echo of its own post. Add a case only when a second store needs to react.

`VaultChangeFeed` (Shared) is the one consumer of `VaultWatching.changes()`: it runs a full scan when it starts, then the incremental reindex through `ReindexVaultUseCase` for each change, and posts `vaultChanged` and `indexUpdated` (for `.rescan`: `indexUpdated`, `spacesChanged`, `vaultRescanned`). `EditorStore` answers `vaultChanged` and `vaultRescanned` with `ConflictPolicy.decide`: ignore, reload, adopt a header-only change, or conflict. On a rescan a missing file is looked up again by its id, so a rename in Finder keeps the note open.

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
| `Ports.live(root:keyValues:)` | Data | builds every live implementation once, with one shared `OwnWrites` for the file store and the watcher |
| `Ports.mock()` | Mocks | in-memory everything, `MockVault` sample |
| `UseCases(ports:)` | Domain | builds every use case |
| `PresentationAssembly(ports:useCases:kv:…)` | Presentation | builds shared objects and stores in dependency order |
| `PresentationAssembly.preview()` | Presentation | mocks for previews |
| `AppWindows(assembly:)` | Presentation | windows and panels |
| `AppContainer` (app delegate) | Composition | `applicationDidFinishLaunching` launches; `application(_:open:)` takes URLs (queued until the windows exist); `applicationWillTerminate` runs the quit job. M1: reads `vault.path` from `UserDefaults`; without it shows `FirstLaunchWindow` (default `~/Documents/Slate`, Choose…, Start). Then runs `VaultBootstrap`, builds `Ports.live`, `UseCases`, `PresentationAssembly`, `AppWindows`, writes the default config and templates, and starts the change feed. On `willTerminate` (a selector observer, so it runs on the main actor) it runs `pendingSave()` off the main actor and waits up to 3 s. Later: `ShellRunner`, hotkeys (`KeyboardShortcuts`), `ServicesProvider`, `LoginItem`, `handle(urls:)` |
| `URLCommandParser` | Domain (M6: pure, shared with the CLI and tested in `SlateDomainTests`) | `URL` → `URLCommand` enum (`new`, `open`, `append`, `capture`, `search`); rejects anything else, and folder names with `/`, a leading `.` or `_` |
| URL handling | Composition, Presentation | `AppContainer.application(_:open:)` parses and passes the command to `AppWindows.handle(_:)`, which shows the panel and calls `NoteListStore.create/open/append`, `SearchStore` or the capture panel |
| `ServicesProvider` | Composition | `@objc addToSlate(_:userData:error:)` → `AppWindows.addFromService` → `CaptureStore.addFromService` → `QuickCaptureUseCase` |
| `CLIContainer` | SlateCLI | `Ports.live` with a `NoopRecorder` and `UseCases`; the folder comes from `--vault`, `SLATE_VAULT` or the app's `vault.path` (`UserDefaultsKeyValueStore(suite:)`). Commands that read the index run an unchanged-files scan first. Opens the app through `open "slate://…"` |

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
| An MCP tool | a schema in `MCPToolCatalog`, a method in `MCPToolRunner+Read` or `+Write`; every write checks `AgentPermissions`, goes through a use case, and ends with `afterWrite` (an `AgentChange` and a snapshot `agent: <tool> <title>`); a test in `MCPToolTests` over a temporary notes folder |
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
- Editor: `MarkdownRoundTripTests` (fixtures in `Fixtures/RoundTrip` and `Fixtures/Foreign`, random documents), `MarkdownWriterTests`, `RichTextControllerTests` (commands, list keys, undo, images, copy, over `EditorHarness` in a window), `KeyboardMapTests`, `RichTextPerformanceTests` (the 5,000-line fixture types under 16 ms per key).
- Presentation: mapper tests (`FolderRowMapper`, `NoteRowMapper`, `FormatBarMapper`, …), store tests over spies (`VaultStore`, `NoteListStore`, `EditorStore` autosave and conflict paths, `SearchStore` merge, `CaptureStore`, `HistoryStore`), `URLCommandParserTests` lives in a Composition test file inside `SlatePresentationTests` only if Composition gets no own target; prefer a sixth target `SlateCompositionTests` when it has more than two suites.
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
- `SlateEditor`: no import of any package module; `import Markdown` only under `Markdown/`; `NSPasteboard` only under `Paste/`; no `layoutManager` token anywhere.
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
| `swift-sdk` (`modelcontextprotocol`, 0.9) | the MCP server `slate mcp`: JSON-RPC over stdio, tool and resource types (ADR 0010) | `SlateCLI` only |

Not used, on purpose: SwiftData and Core Data (files are the store), CloudKit (needs a developer account), `highlight.js` or any JavaScript engine (start time), `STTextView` (dual licence, and `NSTextView` on TextKit 2 is enough), a YAML library (the header is a flat subset).
