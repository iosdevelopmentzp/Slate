import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class EditorStore {
    static let autosaveDelay: Duration = .milliseconds(500)
    static let titleCommitDelay: Duration = .milliseconds(1_500)

    private(set) var document: NoteDocument?
    var text = "" {
        didSet {
            guard text != oldValue, isApplying == false, document != nil else { return }
            schedule(after: Self.autosaveDelay)
            scheduleJournal()
        }
    }
    private(set) var title = ""
    private(set) var saveState: SaveState = .idle
    private(set) var hasConflict = false
    private(set) var followsBody = false
    private(set) var titleFocusToken = 0
    private(set) var bodyFocus: BodyFocus?
    var insertion: MarkdownInsertion?
    var recovered: JournalEntry?
    var isCapturing = false

    @ObservationIgnored private let files: any VaultFileStore
    @ObservationIgnored let index: any SearchIndex
    @ObservationIgnored private let save: SaveNoteUseCase
    @ObservationIgnored private let rename: RenameNoteUseCase
    @ObservationIgnored let navigator: Navigator
    @ObservationIgnored let activity: ActivityLog
    @ObservationIgnored let events: AppEvents
    @ObservationIgnored let clock: any Clock
    @ObservationIgnored let importAttachment: ImportAttachmentUseCase
    @ObservationIgnored let attachScreenshot: AttachScreenshotUseCase
    @ObservationIgnored let workspace: any WorkspaceOpening
    @ObservationIgnored let vaultRoot: URL
    @ObservationIgnored let panel: PanelVisibility
    @ObservationIgnored let toaster: Toaster
    @ObservationIgnored let create: CreateNoteUseCase
    @ObservationIgnored let journal: any JournalStore
    @ObservationIgnored var journalTask: Task<Void, Never>?
    @ObservationIgnored var followsNavigator = true
    @ObservationIgnored var insertionCounter = 0
    @ObservationIgnored private var subscription: SubscriptionToken?
    @ObservationIgnored private var isApplying = false
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private var inFlight: Task<Void, Never>?
    @ObservationIgnored private var pendingCreation: (id: NoteID, caret: Int)?
    @ObservationIgnored private var pendingMatch: (id: NoteID, words: [String])?
    @ObservationIgnored private var bodyCaret: Int?
    @ObservationIgnored var flushBody: () -> Void = {}
    @ObservationIgnored private var focusCounter = 0

    init(
        files: any VaultFileStore,
        index: any SearchIndex,
        save: SaveNoteUseCase,
        rename: RenameNoteUseCase,
        navigator: Navigator,
        activity: ActivityLog,
        events: AppEvents,
        clock: any Clock,
        importAttachment: ImportAttachmentUseCase,
        attachScreenshot: AttachScreenshotUseCase,
        workspace: any WorkspaceOpening,
        vaultRoot: URL,
        panel: PanelVisibility,
        toaster: Toaster,
        create: CreateNoteUseCase,
        journal: any JournalStore
    ) {
        self.files = files
        self.index = index
        self.save = save
        self.rename = rename
        self.navigator = navigator
        self.activity = activity
        self.events = events
        self.clock = clock
        self.importAttachment = importAttachment
        self.attachScreenshot = attachScreenshot
        self.workspace = workspace
        self.vaultRoot = vaultRoot
        self.panel = panel
        self.toaster = toaster
        self.create = create
        self.journal = journal
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            handle(event)
        }
    }

    var isDirty: Bool {
        guard let document else { return false }
        return text != document.body || wantedTitle(for: document) != document.title
    }

    var titleFieldText: String {
        followsBody && title == StemPolicy.untitled ? "" : title
    }

    var isSaving: Bool {
        inFlight != nil
    }

    func editTitle(_ value: String) {
        guard document != nil, value != titleFieldText else { return }
        title = value
        followsBody = false
        schedule(after: Self.titleCommitDelay)
    }

    func submitTitle() {
        requestBodyFocus(atStart: bodyCaret == nil)
        bodyCaret = nil
        Task { await persist() }
    }

    func titleEditingEnded() {
        Task { await persist() }
    }

    func bodyEditingEnded() {
        flushBody()
        Task { await persist() }
    }

    func open(_ id: NoteID?) async {
        if let id, id == document?.id { return }
        await flush()
        guard let id else {
            close()
            return
        }
        do {
            guard let summary = try await index.summary(id: id) else { return }
            let loaded = try NoteCodec.decode(try await files.read(summary.path))
            guard followsNavigator == false || navigator.selectedNote == id else { return }
            show(loaded)
            await checkJournal(for: loaded)
            if let match = pendingMatch, match.id == id {
                pendingMatch = nil
                revealMatch(of: match.words)
            }
            if let creation = pendingCreation, creation.id == id {
                pendingCreation = nil
                followsBody = loaded.title == StemPolicy.untitled
                bodyCaret = creation.caret
                titleFocusToken += 1
            }
        } catch {
            activity.log("Cannot open the note", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func show(_ loaded: NoteDocument) {
        isApplying = true
        document = loaded
        text = loaded.body
        title = loaded.title
        isApplying = false
        hasConflict = false
        followsBody = false
        bodyFocus = nil
        recovered = nil
        saveState = .idle
    }

    func close() {
        saveTask?.cancel()
        isApplying = true
        document = nil
        text = ""
        title = ""
        isApplying = false
        hasConflict = false
        followsBody = false
        recovered = nil
        journalTask?.cancel()
        saveState = .idle
    }

    func flush() async {
        flushBody()
        saveTask?.cancel()
        saveTask = nil
        await persist()
    }

    func updateHeader(_ change: (inout NoteHeader) -> Void) async {
        await flush()
        guard let current = document, hasConflict == false, current.isHeaderOpaque == false else { return }
        var header = current.header
        change(&header)
        guard header != current.header else { return }
        do {
            apply(try await save.execute(current, header: header, body: text), previous: current)
        } catch {
            activity.log("Cannot save the note", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func keepMine() async {
        guard let current = document else { return }
        do {
            let disk = try await files.read(current.path)
            var mine = current
            mine.hash = disk.hash
            isApplying = true
            document = mine
            isApplying = false
            hasConflict = false
            await persist()
        } catch {
            activity.log("Cannot save the note", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func takeTheirs() async {
        guard let current = document else { return }
        do {
            show(try NoteCodec.decode(try await files.read(current.path)))
        } catch {
            activity.log("Cannot read the note", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func pendingSave() -> (@Sendable () async -> Void)? {
        guard let document, isDirty, hasConflict == false else { return nil }
        let body = text
        let wanted = wantedTitle(for: document)
        let save = save
        let rename = rename
        return {
            if wanted != document.title {
                _ = try? await rename.execute(document, title: wanted, body: body)
            } else {
                _ = try? await save.execute(document, header: document.header, body: body)
            }
        }
    }

    private func schedule(after delay: Duration) {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard Task.isCancelled == false, let self else { return }
            await persist()
        }
    }

    private func persist() async {
        if let inFlight {
            await inFlight.value
        }
        guard let document, hasConflict == false, isDirty else { return }
        let task = Task { [weak self] in
            guard let self else { return }
            await performSave(document)
        }
        inFlight = task
        await task.value
        inFlight = nil
    }

    private func performSave(_ original: NoteDocument) async {
        saveState = .saving
        let body = text
        let wanted = wantedTitle(for: original)
        do {
            if wanted != original.title {
                let report = try await rename.execute(original, title: wanted, body: body)
                apply(report.result, previous: original)
                announce(report)
            } else {
                apply(try await save.execute(original, header: original.header, body: body), previous: original)
            }
        } catch {
            saveState = .failed(error.localizedDescription)
            activity.log("Cannot save the note", detail: error.localizedDescription, outcome: .failure)
        }
    }

    private func apply(_ result: SaveResult, previous: NoteDocument) {
        let isCurrent = document?.path == previous.path
        switch result {
        case .saved(let saved), .unchanged(let saved):
            if isCurrent {
                isApplying = true
                document = saved
                if followsBody {
                    title = saved.title
                }
                isApplying = false
            }
            saveState = .saved(clock.now())
            if isCurrent, isDirty == false {
                clearJournal(saved.id)
            }
            if saved.path != previous.path {
                events.post(.noteMoved(from: previous.path, to: saved.path))
            }
            if saved.id != previous.id, navigator.selectedNote == previous.id {
                navigator.select(saved.id)
            }
            events.post(.noteSaved(saved.id))
        case .conflict:
            if isCurrent {
                hasConflict = true
            }
            saveState = .idle
            activity.log("The note changed on disk", detail: previous.path.rawValue, outcome: .failure)
        }
    }

    private func announce(_ report: RenameReport) {
        if report.rewritten.isEmpty == false {
            events.post(.vaultChanged(Set(report.rewritten)))
            let count = report.rewritten.count
            toaster.show(count == 1 ? "Updated the link in 1 note" : "Updated the links in \(count) notes")
        }
        if report.failed.isEmpty == false {
            activity.log("Cannot update links in some notes", detail: report.failed.map(\.rawValue).joined(separator: "\n"), outcome: .failure)
        }
    }

    private func wantedTitle(for document: NoteDocument) -> String {
        if followsBody {
            return TitlePolicy.title(fromBody: text) ?? document.title
        }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? StemPolicy.untitled : title
    }

    private func revealMatch(of words: [String]) {
        guard SearchHighlightPolicy.ranges(of: words, in: text).isEmpty == false else { return }
        requestBodyFocus(atStart: false, words: words)
    }

    private func requestBodyFocus(atStart: Bool, words: [String] = []) {
        focusCounter += 1
        bodyFocus = BodyFocus(token: focusCounter, atStart: atStart, words: words)
    }

    private func handle(_ event: AppEvent) {
        switch event {
        case .noteCreated(let id, let caret):
            pendingCreation = (id, caret)
        case .searchOpened(let id, let words):
            if document?.id == id {
                revealMatch(of: words)
            } else {
                pendingMatch = (id, words)
            }
        case .vaultChanged(let paths):
            guard let path = document?.path, paths.contains(path) else { return }
            Task { await checkDisk(relocate: false) }
        case .vaultRescanned:
            Task { await checkDisk(relocate: true) }
        case .noteMoved(let from, let to):
            guard var moved = document, moved.path == from else { return }
            moved.path = to
            moved.meta = FileMeta(path: to, created: moved.meta.created, modified: moved.meta.modified, size: moved.meta.size)
            isApplying = true
            document = moved
            isApplying = false
        case .noteSaved(let id):
            guard id == document?.id, inFlight == nil else { return }
            Task { await checkDisk(relocate: false) }
        case .noteTrashed(let path):
            guard document?.path == path else { return }
            close()
        default:
            break
        }
    }

    private func checkDisk(relocate: Bool) async {
        guard inFlight == nil, var current = document else { return }
        let exists = (try? await files.meta(current.path)).flatMap { $0 } != nil
        if relocate, exists == false {
            guard let moved = try? await index.summary(id: current.id), moved.path != current.path else {
                if isDirty == false { close() }
                return
            }
            handle(.noteMoved(from: current.path, to: moved.path))
            current.path = moved.path
        }
        do {
            let disk = try NoteCodec.decode(try await files.read(current.path))
            guard let latest = document, latest.path == current.path else { return }
            switch ConflictPolicy.decide(loaded: latest, disk: disk, isDirty: isDirty) {
            case .ignore:
                break
            case .reload:
                show(disk)
            case .adoptHeader:
                let keepsTitle = title != latest.title
                isApplying = true
                document = disk
                if keepsTitle == false { title = disk.title }
                isApplying = false
            case .conflict:
                hasConflict = true
                activity.log("The note changed on disk", detail: latest.path.rawValue, outcome: .failure)
            }
        } catch VaultError.notFound {
            if isDirty {
                hasConflict = true
            } else {
                close()
            }
        } catch {
            activity.log("Cannot read the note", detail: error.localizedDescription, outcome: .failure)
        }
    }
}
