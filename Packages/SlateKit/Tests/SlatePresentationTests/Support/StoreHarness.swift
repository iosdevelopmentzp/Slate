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
        navigator: navigator,
        activity: activity,
        events: events
    )
    lazy var noteList = NoteListStore(
        index: ports.index,
        trash: ports.trash,
        create: useCases.create,
        updateHeader: useCases.updateHeader,
        move: useCases.move,
        archive: useCases.archive,
        duplicate: useCases.duplicate,
        trashNote: useCases.trash,
        restore: useCases.restore,
        navigator: navigator,
        toaster: toaster,
        activity: activity,
        events: events,
        store: keyValues
    )
    lazy var editor = EditorStore(
        files: ports.files,
        index: ports.index,
        save: useCases.save,
        rename: useCases.rename,
        navigator: navigator,
        activity: activity,
        events: events,
        clock: ports.clock
    )
    lazy var feed = VaultChangeFeed(watcher: ports.watcher, reindex: useCases.reindex, activity: activity, events: events)

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
