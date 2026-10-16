import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class NoteListStore {
    var summaries: [NoteSummary] = []
    var trashItems: [TrashItem] = []
    var filterText = ""
    var sort: NoteSort {
        didSet {
            guard sort != oldValue else { return }
            store.set(sort.rawValue, forKey: Keys.sort)
        }
    }
    private(set) var isLoading = true
    private(set) var failure: String?
    private(set) var confirmingTrash: NoteID?

    @ObservationIgnored private let index: any SearchIndex
    @ObservationIgnored private let trashRepository: any TrashRepository
    @ObservationIgnored private let create: CreateNoteUseCase
    @ObservationIgnored private let updateHeader: UpdateHeaderUseCase
    @ObservationIgnored private let move: MoveNoteUseCase
    @ObservationIgnored private let archive: ArchiveNoteUseCase
    @ObservationIgnored private let duplicate: DuplicateNoteUseCase
    @ObservationIgnored private let trashNote: TrashNoteUseCase
    @ObservationIgnored private let restore: RestoreNoteUseCase
    @ObservationIgnored private let navigator: Navigator
    @ObservationIgnored private let toaster: Toaster
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?
    @ObservationIgnored private var confirmationTask: Task<Void, Never>?

    init(
        index: any SearchIndex,
        trash: any TrashRepository,
        create: CreateNoteUseCase,
        updateHeader: UpdateHeaderUseCase,
        move: MoveNoteUseCase,
        archive: ArchiveNoteUseCase,
        duplicate: DuplicateNoteUseCase,
        trashNote: TrashNoteUseCase,
        restore: RestoreNoteUseCase,
        navigator: Navigator,
        toaster: Toaster,
        activity: ActivityLog,
        events: AppEvents,
        store: any KeyValueStore
    ) {
        self.index = index
        trashRepository = trash
        self.create = create
        self.updateHeader = updateHeader
        self.move = move
        self.archive = archive
        self.duplicate = duplicate
        self.trashNote = trashNote
        self.restore = restore
        self.navigator = navigator
        self.toaster = toaster
        self.activity = activity
        self.events = events
        self.store = store
        sort = store.string(forKey: Keys.sort).flatMap(NoteSort.init(rawValue:)) ?? .updated
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            handle(event)
        }
    }

    var source: ListSource {
        navigator.source
    }

    var visibleNotes: [NoteSummary] {
        let inSource: [NoteSummary]
        switch source {
        case .all: inSource = summaries
        case .space(let space): inSource = summaries.filter { $0.space == space }
        case .trash: inSource = []
        }
        let query = filterText.trimmingCharacters(in: .whitespacesAndNewlines)
        let matching = query.isEmpty ? inSource : inSource.filter { $0.title.localizedCaseInsensitiveContains(query) }
        return matching.sorted(by: order)
    }

    var visibleTrash: [TrashItem] {
        let query = filterText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return trashItems }
        return trashItems.filter { $0.originalPath.stem.localizedCaseInsensitiveContains(query) }
    }

    var selected: NoteSummary? {
        guard let id = navigator.selectedNote else { return nil }
        return summaries.first { $0.id == id }
    }

    func count(in space: SpaceName?) -> Int {
        guard let space else { return summaries.count }
        return summaries.filter { $0.space == space }.count
    }

    func refresh() async {
        await refreshTask.run { [weak self] in
            guard let self else { return }
            do {
                let loaded = try await index.summaries(space: nil)
                if loaded != summaries { summaries = loaded }
                if source == .trash {
                    trashItems = try await trashRepository.items()
                }
                failure = nil
            } catch {
                failure = error.localizedDescription
                activity.log("Cannot read the notes", detail: error.localizedDescription, outcome: .failure)
            }
            isLoading = false
        }
    }

    func show(_ source: ListSource) {
        navigator.show(source)
        cancelTrash()
        if source == .trash {
            Task { await refresh() }
            return
        }
        if let selected, source == .all || selected.space == source.space {
            return
        }
        navigator.select(visibleNotes.first?.id)
    }

    func select(_ id: NoteID?) {
        navigator.select(id)
    }

    func createNote(type: String? = nil) async {
        let space = type == nil ? source.space : nil
        do {
            let created = try await create.execute(NoteDraft(type: type, space: space))
            let id = created.document.id
            await refresh()
            if let space = created.document.path.space, source != .all, source != .space(space) {
                navigator.show(.space(space))
            }
            events.post(.noteCreated(id, caret: created.caret))
            navigator.select(id)
        } catch {
            activity.log("Cannot create the note", detail: error.localizedDescription, outcome: .failure)
            toaster.show("The note was not created. See Activity.")
        }
    }

    func togglePin(_ summary: NoteSummary) async {
        let pinned = summary.pinned == false
        await run("Cannot change the pin", path: summary.path) { [updateHeader] in
            _ = try await updateHeader.execute(summary.path) { $0.pinned = pinned }
        }
    }

    func moveNote(_ summary: NoteSummary, to space: SpaceName) async {
        do {
            let target = try await move.execute(summary.path, to: space)
            await finishMove(summary, to: target, message: "Moved to \(space.rawValue)")
        } catch {
            activity.log("Cannot move the note", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func archiveNote(_ summary: NoteSummary) async {
        do {
            let target = try await archive.execute(summary.path)
            await finishMove(summary, to: target, message: target.space.map { "Moved to \($0.rawValue)" } ?? "Archived")
        } catch {
            activity.log("Cannot archive the note", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func duplicateNote(_ summary: NoteSummary) async {
        do {
            let copy = try await duplicate.execute(summary.path)
            await refresh()
            events.post(.noteCreated(copy.id, caret: 0))
            navigator.select(copy.id)
        } catch {
            activity.log("Cannot duplicate the note", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func requestTrash(_ id: NoteID) {
        confirmingTrash = id
        confirmationTask?.cancel()
        confirmationTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard Task.isCancelled == false, let self else { return }
            cancelTrash()
        }
    }

    func cancelTrash() {
        confirmationTask?.cancel()
        confirmingTrash = nil
    }

    func confirmTrash(_ summary: NoteSummary) async {
        cancelTrash()
        let next = neighbour(of: summary.id)
        do {
            let item = try await trashNote.execute(summary.path)
            events.post(.noteTrashed(summary.path))
            if navigator.selectedNote == summary.id {
                navigator.select(next)
            }
            await refresh()
            toaster.show("Moved to the Trash", action: ToastAction(title: "Undo") { [weak self] in
                guard let self else { return }
                Task { await self.restoreItem(item) }
            })
        } catch {
            activity.log("Cannot move the note to the Trash", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func restoreItem(_ item: TrashItem) async {
        do {
            let document = try await restore.execute(item)
            trashItems.removeAll { $0.path == item.path }
            await refresh()
            if source != .trash {
                navigator.select(document.id)
            }
            toaster.show("Restored to \(document.path.space?.rawValue ?? "the notes folder")")
        } catch {
            activity.log("Cannot restore the note", detail: error.localizedDescription, outcome: .failure)
        }
    }

    private func finishMove(_ summary: NoteSummary, to target: VaultPath, message: String) async {
        events.post(.noteMoved(from: summary.path, to: target))
        await refresh()
        if let space = source.space, target.space != space, navigator.selectedNote == summary.id {
            navigator.select(visibleNotes.first?.id)
        }
        toaster.show(message)
    }

    private func run(_ failureTitle: String, path: VaultPath, work: () async throws -> Void) async {
        do {
            try await work()
            events.post(.vaultChanged([path]))
            await refresh()
        } catch {
            activity.log(failureTitle, detail: error.localizedDescription, outcome: .failure)
        }
    }

    private func neighbour(of id: NoteID) -> NoteID? {
        let notes = visibleNotes
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return nil }
        if notes.indices.contains(index + 1) { return notes[index + 1].id }
        if index > 0 { return notes[index - 1].id }
        return nil
    }

    private func handle(_ event: AppEvent) {
        switch event {
        case .indexUpdated, .noteSaved:
            Task { [weak self] in
                guard let self else { return }
                await refresh()
            }
        default:
            break
        }
    }

    private func order(_ lhs: NoteSummary, _ rhs: NoteSummary) -> Bool {
        if lhs.pinned != rhs.pinned {
            return lhs.pinned
        }
        switch sort {
        case .updated:
            return lhs.updated > rhs.updated
        case .created:
            return lhs.created > rhs.created
        case .title:
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }

    private enum Keys {
        static let sort = "list.sort"
    }
}
