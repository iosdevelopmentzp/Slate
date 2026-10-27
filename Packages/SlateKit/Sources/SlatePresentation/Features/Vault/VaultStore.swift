import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class VaultStore {
    static let newFolderName = "New folder"
    static let newProjectName = "New project"
    static let confirmationTime: Duration = .seconds(5)

    var config = SpacesConfig(spaces: []) {
        didSet { rebuildTree() }
    }
    var draftName = ""
    private(set) var editing: FolderEdit?
    private(set) var confirmingDelete: FolderPath?
    private(set) var subfolders: [FolderPath] = [] {
        didSet { rebuildTree() }
    }
    private(set) var tree = FolderTree([])
    private(set) var moveTargets: [MoveTargetModel] = []
    private(set) var expanded: Set<FolderPath>

    @ObservationIgnored private let repository: any VaultConfigRepository
    @ObservationIgnored private let createSpace: CreateSpaceUseCase
    @ObservationIgnored private let renameSpace: RenameSpaceUseCase
    @ObservationIgnored private let deleteSpace: DeleteSpaceUseCase
    @ObservationIgnored private let restoreSpace: RestoreSpaceUseCase
    @ObservationIgnored private let files: any VaultFileStore
    @ObservationIgnored private let createFolder: CreateFolderUseCase
    @ObservationIgnored private let renameFolder: RenameFolderUseCase
    @ObservationIgnored private let deleteFolder: DeleteFolderUseCase
    @ObservationIgnored private let moveFolder: MoveFolderUseCase
    @ObservationIgnored private let restoreFolder: RestoreFolderUseCase
    @ObservationIgnored private let setProject: SetProjectUseCase
    @ObservationIgnored private let createProject: CreateProjectUseCase
    @ObservationIgnored private let startTask: StartTaskUseCase
    @ObservationIgnored private let importFolder: ImportFolderUseCase
    @ObservationIgnored private let linkRepository: LinkRepositoryUseCase
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let navigator: Navigator
    @ObservationIgnored private let toaster: Toaster
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?
    @ObservationIgnored private var confirmationTask: Task<Void, Never>?

    init(
        config: any VaultConfigRepository,
        createSpace: CreateSpaceUseCase,
        renameSpace: RenameSpaceUseCase,
        deleteSpace: DeleteSpaceUseCase,
        restoreSpace: RestoreSpaceUseCase,
        files: any VaultFileStore,
        createFolder: CreateFolderUseCase,
        renameFolder: RenameFolderUseCase,
        deleteFolder: DeleteFolderUseCase,
        moveFolder: MoveFolderUseCase,
        restoreFolder: RestoreFolderUseCase,
        setProject: SetProjectUseCase,
        createProject: CreateProjectUseCase,
        startTask: StartTaskUseCase,
        importFolder: ImportFolderUseCase,
        linkRepository: LinkRepositoryUseCase,
        store: any KeyValueStore,
        navigator: Navigator,
        toaster: Toaster,
        activity: ActivityLog,
        events: AppEvents
    ) {
        repository = config
        self.createSpace = createSpace
        self.renameSpace = renameSpace
        self.deleteSpace = deleteSpace
        self.restoreSpace = restoreSpace
        self.files = files
        self.createFolder = createFolder
        self.renameFolder = renameFolder
        self.deleteFolder = deleteFolder
        self.moveFolder = moveFolder
        self.restoreFolder = restoreFolder
        self.setProject = setProject
        self.createProject = createProject
        self.startTask = startTask
        self.importFolder = importFolder
        self.linkRepository = linkRepository
        self.store = store
        expanded = Set((store.strings(forKey: Keys.expanded) ?? []).map(FolderPath.init(rawValue:)))
        self.navigator = navigator
        self.toaster = toaster
        self.activity = activity
        self.events = events
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .spacesChanged, .vaultRescanned, .vaultChanged: break
            default: return
            }
            Task { await self.refresh() }
        }
    }

    var spaces: [Space] {
        config.spaces
    }

    var folderSpaces: [Space] {
        config.spaces.filter { $0.isProject == false }
    }

    var projects: [Space] {
        config.spaces.filter(\.isProject)
    }

    func isProject(_ space: SpaceName) -> Bool {
        config.space(space)?.isProject ?? false
    }

    var defaultFolder: SpaceName {
        config.captureSpace
    }

    func refresh() async {
        await refreshTask.run { [weak self] in
            guard let self else { return }
            do {
                let loaded = try await repository.spaces()
                if loaded != config { config = loaded }
                let found = try await files.folders()
                if found != subfolders { subfolders = found }
            } catch {
                activity.log("Cannot read the folders", detail: error.localizedDescription, outcome: .failure)
            }
        }
    }

    func startNewFolder() {
        cancelDelete()
        draftName = uniqueNewName()
        editing = .new
    }

    func startNewProject() {
        cancelDelete()
        draftName = Self.uniqueName(among: spaces.map(\.folder.rawValue), base: Self.newProjectName)
        editing = .newProject
    }

    func startNewTask(in project: SpaceName) {
        cancelDelete()
        setExpanded(FolderPath(space: project), true)
        draftName = ""
        editing = .newTask(project)
    }

    func startNewFolder(in parent: FolderPath) {
        cancelDelete()
        setExpanded(parent, true)
        let taken = children(of: parent).map(\.name)
        draftName = Self.uniqueName(among: taken)
        editing = .newInside(parent)
    }

    func startRename(_ space: SpaceName) {
        cancelDelete()
        draftName = space.rawValue
        editing = .rename(space)
    }

    func startRename(folder: FolderPath) {
        guard folder.isSpace == false else {
            startRename(folder.space)
            return
        }
        cancelDelete()
        draftName = folder.name
        editing = .renameFolder(folder)
    }

    func children(of parent: FolderPath) -> [FolderPath] {
        tree.children(of: parent)
    }

    private func rebuildTree() {
        tree = FolderTree(subfolders)
        moveTargets = NoteRowMapper.moveTargets(spaces: config.spaces, tree: tree)
    }

    func isExpanded(_ folder: FolderPath) -> Bool {
        expanded.contains(folder)
    }

    func setExpanded(_ folder: FolderPath, _ isExpanded: Bool) {
        guard expanded.contains(folder) != isExpanded else { return }
        if isExpanded {
            expanded.insert(folder)
        } else {
            expanded.remove(folder)
        }
        saveExpanded()
    }

    func cancelEdit() {
        editing = nil
        draftName = ""
    }

    @discardableResult
    func commitEdit() async -> Bool {
        guard let editing else { return false }
        let name = draftName
        let done: Bool
        switch editing {
        case .new:
            done = await create(named: name)
        case .newProject:
            done = await createProject(named: name)
        case .newTask(let project):
            done = await startTask(named: name, in: project)
        case .newInside(let parent):
            done = await create(named: name, in: parent)
        case .rename(let space):
            done = await rename(space, to: name)
        case .renameFolder(let folder):
            done = await rename(folder: folder, to: name)
        }
        if done {
            cancelEdit()
        }
        return done
    }

    @discardableResult
    func create(named name: String) async -> Bool {
        do {
            let space = try await createSpace.execute(name: name)
            await refresh()
            navigator.show(.space(space))
            return true
        } catch {
            report("Cannot create the folder", error)
            return false
        }
    }

    @discardableResult
    func createProject(named name: String) async -> Bool {
        do {
            let space = try await createProject.execute(name: name)
            await refresh()
            navigator.show(.space(space))
            return true
        } catch {
            report("Cannot create the project", error)
            return false
        }
    }

    @discardableResult
    func startTask(named name: String, in project: SpaceName) async -> Bool {
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { return true }
        do {
            let created = try await startTask.execute(in: project, title: name)
            await refresh()
            if let folder = created.document.path.folderPath {
                navigator.show(.showing(folder))
            }
            events.post(.indexUpdated)
            events.post(.noteCreated(created.document.id, caret: created.caret))
            navigator.select(created.document.id)
            return true
        } catch {
            report("Cannot start the task", error)
            return false
        }
    }

    func importProject(from folder: URL) async {
        do {
            let imported = try await importFolder.execute(folder)
            await refresh()
            navigator.show(.space(imported.space))
            events.post(.indexUpdated)
            events.post(.vaultRescanned)
            toaster.show(Self.importedMessage(imported))
        } catch {
            report("Cannot import the folder", error)
        }
    }

    static func importedMessage(_ imported: ImportedProject) -> String {
        let notes = imported.report.notes == 1 ? "1 note" : "\(imported.report.notes) notes"
        let files = imported.report.files == 1 ? "1 file" : "\(imported.report.files) files"
        guard imported.report.notesOnly == false else {
            return "Imported \(notes) into \(imported.space.rawValue). From a code repository Slate copies only the notes."
        }
        return "Imported \(notes) and \(files) into \(imported.space.rawValue)"
    }

    func setProject(_ isProject: Bool, for space: SpaceName) async {
        do {
            let project = isProject ? (config.space(space)?.project ?? ProjectInfo()) : nil
            try await setProject.execute(space, project: project)
            await refresh()
        } catch {
            report(isProject ? "Cannot make the folder a project" : "Cannot make the project a folder", error)
        }
    }

    func linkRepository(_ directory: URL, to space: SpaceName) async {
        do {
            let project = try await linkRepository.execute(space, directory: directory)
            await refresh()
            toaster.show(project.remote == nil ? "Linked \(directory.lastPathComponent)" : "Linked \(directory.lastPathComponent) and its remote")
        } catch {
            report("Cannot link the repository", error)
        }
    }

    @discardableResult
    func create(named name: String, in parent: FolderPath) async -> Bool {
        do {
            let folder = try await createFolder.execute(name: name, in: parent)
            await refresh()
            setExpanded(parent, true)
            navigator.show(.folder(folder))
            return true
        } catch {
            report("Cannot create the folder", error)
            return false
        }
    }

    @discardableResult
    func rename(folder: FolderPath, to name: String) async -> Bool {
        guard name.trimmingCharacters(in: .whitespacesAndNewlines) != folder.name else { return true }
        do {
            let renamed = try await renameFolder.execute(folder, to: name)
            expanded = Set(expanded.map { $0.moved(from: folder, to: renamed) })
            saveExpanded()
            await refresh()
            if case .folder(let shown) = navigator.source {
                navigator.show(.folder(shown.moved(from: folder, to: renamed)))
            }
            events.post(.indexUpdated)
            events.post(.vaultRescanned)
            return true
        } catch {
            report("Cannot rename the folder", error)
            return false
        }
    }

    @discardableResult
    func rename(_ space: SpaceName, to name: String) async -> Bool {
        guard name.trimmingCharacters(in: .whitespacesAndNewlines) != space.rawValue else { return true }
        do {
            let renamed = try await renameSpace.execute(space, to: name)
            let old = FolderPath(space: space)
            let new = FolderPath(space: renamed)
            expanded = Set(expanded.map { $0.moved(from: old, to: new) })
            saveExpanded()
            await refresh()
            switch navigator.source {
            case .space(space): navigator.show(.space(renamed))
            case .folder(let shown): navigator.show(.folder(shown.moved(from: old, to: new)))
            default: break
            }
            events.post(.indexUpdated)
            events.post(.vaultRescanned)
            return true
        } catch {
            report("Cannot rename the folder", error)
            return false
        }
    }

    func move(folder: FolderPath, into parent: FolderPath?) async {
        do {
            guard let done = try await moveFolder.execute(folder, into: parent) else { return }
            await show(done.from, movedTo: done.to)
            if let parent { setExpanded(parent, true) }
            toaster.show(Self.movedMessage(done), action: ToastAction(title: "Undo") { [weak self] in
                guard let self else { return }
                Task { await self.undoMove(done) }
            })
        } catch {
            report("Cannot move the folder", error)
        }
    }

    func undoMove(_ done: FolderMove) async {
        do {
            try await moveFolder.undo(done)
            await show(done.to, movedTo: done.from)
            toaster.show("\(done.from.name) is back")
        } catch {
            report("Cannot move the folder back", error)
        }
    }

    static func movedMessage(_ done: FolderMove) -> String {
        guard let parent = done.to.parent else { return "Moved \(done.from.name) to the top level" }
        return "Moved \(done.from.name) into \(parent.name)"
    }

    private func show(_ old: FolderPath, movedTo new: FolderPath) async {
        expanded = Set(expanded.map { $0.moved(from: old, to: new) })
        saveExpanded()
        await refresh()
        if let shown = navigator.source.folder, shown == old || old.contains(shown) {
            navigator.show(.showing(shown.moved(from: old, to: new)))
        }
        events.post(.indexUpdated)
        events.post(.vaultRescanned)
    }

    func requestDelete(_ space: SpaceName) {
        requestDelete(folder: FolderPath(space: space))
    }

    func requestDelete(folder: FolderPath) {
        cancelEdit()
        confirmingDelete = folder
        confirmationTask?.cancel()
        confirmationTask = Task { [weak self] in
            try? await Task.sleep(for: Self.confirmationTime)
            guard Task.isCancelled == false, let self else { return }
            cancelDelete()
        }
    }

    func cancelDelete() {
        confirmationTask?.cancel()
        confirmingDelete = nil
    }

    func confirmDelete(folder: FolderPath) async {
        guard folder.isSpace == false else {
            await confirmDelete(folder.space)
            return
        }
        cancelDelete()
        do {
            let deletion = try await deleteFolder.execute(folder)
            expanded = expanded.filter { $0 != folder && folder.contains($0) == false }
            saveExpanded()
            await refresh()
            if let shown = navigator.source.folder, shown == folder || folder.contains(shown) {
                navigator.show(.showing(deletion.target))
            }
            announce(deletion.moves.map { ($0.from, $0.to) })
            toaster.show(Self.deletedMessage(name: folder.name, count: deletion.moves.count, target: deletion.target.name), action: ToastAction(title: "Undo") { [weak self] in
                guard let self else { return }
                Task { await self.undoDelete(deletion) }
            })
        } catch {
            report("Cannot delete the folder", error)
        }
    }

    func undoDelete(_ deletion: FolderDeletion) async {
        do {
            let restored = try await restoreFolder.execute(deletion)
            await refresh()
            announce(restored.map { ($0.from, $0.to) })
            if let parent = deletion.folder.parent { setExpanded(parent, true) }
            navigator.show(.folder(deletion.folder))
            toaster.show("\(deletion.folder.name) is back")
        } catch {
            report("Cannot bring the folder back", error)
        }
    }

    func confirmDelete(_ space: SpaceName) async {
        cancelDelete()
        do {
            let deletion = try await deleteSpace.execute(space)
            expanded = expanded.filter { $0.space != space }
            saveExpanded()
            await refresh()
            if navigator.source.space == space {
                navigator.show(.space(deletion.target))
            }
            announce(deletion.moves.map { ($0.from, $0.to) })
            toaster.show(Self.deletedMessage(name: deletion.space.folder.rawValue, count: deletion.moves.count, target: deletion.target.rawValue), action: ToastAction(title: "Undo") { [weak self] in
                guard let self else { return }
                Task { await self.undoDelete(deletion) }
            })
        } catch {
            report("Cannot delete the folder", error)
        }
    }

    func undoDelete(_ deletion: SpaceDeletion) async {
        do {
            let restored = try await restoreSpace.execute(deletion)
            await refresh()
            announce(restored.map { ($0.from, $0.to) })
            navigator.show(.space(deletion.space.folder))
            toaster.show("\(deletion.space.folder.rawValue) is back")
        } catch {
            report("Cannot bring the folder back", error)
        }
    }

    func move(_ space: SpaceName, by offset: Int) async {
        guard let index = config.spaces.firstIndex(where: { $0.folder == space }), let target = neighbor(of: index, by: offset) else { return }
        var updated = config
        updated.spaces.swapAt(index, target)
        await save(updated)
    }

    func setIcon(_ icon: String, for space: SpaceName) async {
        var updated = config
        guard let index = updated.spaces.firstIndex(where: { $0.folder == space }) else { return }
        updated.spaces[index].icon = icon
        await save(updated)
    }

    func setColor(_ color: SpaceColor, for space: SpaceName) async {
        var updated = config
        guard let index = updated.spaces.firstIndex(where: { $0.folder == space }) else { return }
        updated.spaces[index].color = color
        await save(updated)
    }

    func setCaptureSpace(_ space: SpaceName) async {
        var updated = config
        updated.captureSpace = space
        await save(updated)
    }

    func canMove(_ space: SpaceName, by offset: Int) -> Bool {
        guard let index = config.spaces.firstIndex(where: { $0.folder == space }) else { return false }
        return neighbor(of: index, by: offset) != nil
    }

    private func neighbor(of index: Int, by offset: Int) -> Int? {
        let group = config.spaces[index].isProject
        let candidates = offset < 0 ? Array(config.spaces.indices.prefix(upTo: index).reversed()) : Array(config.spaces.indices.suffix(from: index + 1))
        return candidates.first { config.spaces[$0].isProject == group }
    }

    private func uniqueNewName() -> String {
        Self.uniqueName(among: spaces.map(\.folder.rawValue))
    }

    private static func uniqueName(among taken: [String], base: String = VaultStore.newFolderName) -> String {
        var name = base
        var number = 2
        while taken.contains(where: { StemPolicy.isSame($0, name) }) {
            name = "\(base) \(number)"
            number += 1
        }
        return name
    }

    private func announce(_ moves: [(VaultPath, VaultPath)]) {
        for (from, to) in moves {
            events.post(.noteMoved(from: from, to: to))
        }
        events.post(.indexUpdated)
    }

    private static func deletedMessage(name: String, count: Int, target: String) -> String {
        switch count {
        case 0: return "Deleted \(name)"
        case 1: return "Deleted \(name). 1 note moved to \(target)."
        default: return "Deleted \(name). \(count) notes moved to \(target)."
        }
    }

    private func saveExpanded() {
        store.set(expanded.map(\.rawValue).sorted(), forKey: Keys.expanded)
    }

    private enum Keys {
        static let expanded = "sidebar.expanded"
    }

    private func report(_ title: String, _ error: any Error) {
        activity.log(title, detail: error.localizedDescription, outcome: .failure)
        toaster.show(error.localizedDescription)
    }

    private func save(_ updated: SpacesConfig) async {
        let previous = config
        config = updated
        do {
            try await repository.saveSpaces(updated)
        } catch {
            config = previous
            activity.log("Cannot save the folders", detail: error.localizedDescription, outcome: .failure)
        }
    }
}
