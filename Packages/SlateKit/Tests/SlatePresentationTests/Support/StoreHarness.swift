import Foundation
import SlateDomain
import SlateMocks
import SlateTestSupport
@testable import SlatePresentation

@MainActor
final class StoreHarness {
    let keyValues = InMemoryKeyValueStore()
    let ports: Ports
    let spies: PortSpies
    let useCases: UseCases
    let events = AppEvents()
    let activity = ActivityLog()
    private(set) var copied: [String] = []
    private(set) var posted: [AppEvent] = []
    private var recorder: SubscriptionToken?

    lazy var navigator = Navigator(store: keyValues)
    lazy var toaster = Toaster { [weak self] in self?.copied.append($0) }
    lazy var vault = VaultStore(
        config: ports.config,
        createSpace: useCases.createSpace,
        renameSpace: useCases.renameSpace,
        deleteSpace: useCases.deleteSpace,
        restoreSpace: useCases.restoreSpace,
        files: ports.files,
        createFolder: useCases.createFolder,
        renameFolder: useCases.renameFolder,
        deleteFolder: useCases.deleteFolder,
        restoreFolder: useCases.restoreFolder,
        setProject: useCases.setProject,
        createProject: useCases.createProject,
        store: keyValues,
        navigator: navigator,
        toaster: toaster,
        activity: activity,
        events: events
    )
    lazy var noteList = NoteListStore(
        index: ports.index,
        trash: ports.trash,
        create: useCases.create,
        updateHeader: useCases.updateHeader,
        move: useCases.move,
        duplicate: useCases.duplicate,
        trashNote: useCases.trash,
        restore: useCases.restore,
        append: useCases.append,
        openTarget: useCases.openTarget,
        navigator: navigator,
        toaster: toaster,
        activity: activity,
        events: events,
        store: keyValues,
        vaultRoot: URL(fileURLWithPath: "/vault", isDirectory: true)
    )
    lazy var files = FolderFilesStore(
        files: ports.files,
        workspace: ports.workspace,
        exporter: ports.exporter,
        toaster: toaster,
        activity: activity,
        events: events,
        vaultRoot: URL(fileURLWithPath: "/vault", isDirectory: true)
    )
    lazy var editor = EditorStore(
        files: ports.files,
        index: ports.index,
        save: useCases.save,
        rename: useCases.rename,
        navigator: navigator,
        activity: activity,
        events: events,
        clock: ports.clock,
        importAttachment: useCases.importAttachment,
        attachScreenshot: useCases.attachScreenshot,
        workspace: ports.workspace,
        exporter: ports.exporter,
        vaultRoot: URL(fileURLWithPath: "/vault", isDirectory: true),
        panel: panelVisibility,
        toaster: toaster,
        create: useCases.create,
        journal: ports.journal
    )
    lazy var settings = SettingsStore(
        store: keyValues,
        config: ports.config,
        loginItem: ports.loginItem,
        system: ports.system,
        index: ports.index,
        reindex: useCases.reindex,
        history: ports.history,
        vaultPath: "/vault",
        activity: activity,
        events: events
    )
    lazy var capture = CaptureStore(capture: useCases.capture, navigator: navigator, toaster: toaster, activity: activity, events: events)
    lazy var history = HistoryStore(
        history: ports.history,
        snapshot: useCases.snapshot,
        restoreVersion: useCases.restoreVersion,
        purgeTrash: useCases.purgeTrash,
        store: keyValues,
        activity: activity,
        toaster: toaster,
        events: events
    )
    lazy var search = SearchStore(index: ports.index, notes: noteList, navigator: navigator, clock: ports.clock, activity: activity, events: events)
    lazy var panelVisibility = PanelVisibility()
    lazy var feed = VaultChangeFeed(watcher: ports.watcher, reindex: useCases.reindex, activity: activity, events: events, agentChanges: ports.agentChanges, clock: ports.clock)

    init() {
        (ports, spies) = Ports.spies(keyValues: keyValues)
        useCases = UseCases(ports: ports)
        recorder = events.subscribe { [weak self] in self?.posted.append($0) }
    }

    @discardableResult
    func seed(_ path: String, id: String? = nil, title: String? = nil, type: String? = nil, pinned: Bool? = nil, body: String = "") -> VaultPath {
        let vaultPath = VaultPath(rawValue: path)
        spies.files.seed(vaultPath, NoteText.make(id: id, title: title ?? vaultPath.stem, type: type, pinned: pinned, body: body))
        return vaultPath
    }

    func index() async throws {
        _ = try await useCases.reindex.execute(.all)
    }

    func document(at path: VaultPath) async throws -> NoteDocument {
        try NoteCodec.decode(try await spies.files.read(path))
    }

    func clearPosted() {
        posted.removeAll()
    }
}
