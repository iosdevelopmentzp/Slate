import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class VaultStore {
    static let newFolderName = "New folder"
    static let confirmationTime: Duration = .seconds(5)

    var config = SpacesConfig(spaces: [])
    var draftName = ""
    private(set) var editing: FolderEdit?
    private(set) var confirmingDelete: SpaceName?

    @ObservationIgnored private let repository: any VaultConfigRepository
    @ObservationIgnored private let createSpace: CreateSpaceUseCase
    @ObservationIgnored private let renameSpace: RenameSpaceUseCase
    @ObservationIgnored private let deleteSpace: DeleteSpaceUseCase
    @ObservationIgnored private let restoreSpace: RestoreSpaceUseCase
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
        self.navigator = navigator
        self.toaster = toaster
        self.activity = activity
        self.events = events
        subscription = events.subscribe { [weak self] event in
            guard let self, event == .spacesChanged || event == .vaultRescanned else { return }
            Task { await self.refresh() }
        }
    }

    var spaces: [Space] {
        config.spaces
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

    func startRename(_ space: SpaceName) {
        cancelDelete()
        draftName = space.rawValue
        editing = .rename(space)
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
        case .rename(let space):
            done = await rename(space, to: name)
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
    func rename(_ space: SpaceName, to name: String) async -> Bool {
        guard name.trimmingCharacters(in: .whitespacesAndNewlines) != space.rawValue else { return true }
        do {
            let renamed = try await renameSpace.execute(space, to: name)
            await refresh()
            if navigator.source == .space(space) {
                navigator.show(.space(renamed))
            }
            events.post(.indexUpdated)
            events.post(.vaultRescanned)
            return true
        } catch {
            report("Cannot rename the folder", error)
            return false
        }
    }

    func requestDelete(_ space: SpaceName) {
        cancelEdit()
        confirmingDelete = space
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

    func confirmDelete(_ space: SpaceName) async {
        cancelDelete()
        do {
            let deletion = try await deleteSpace.execute(space)
            await refresh()
            if navigator.source == .space(space) {
                navigator.show(.space(deletion.target))
            }
            announce(deletion.moves.map { ($0.from, $0.to) })
            toaster.show(deletedMessage(deletion), action: ToastAction(title: "Undo") { [weak self] in
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
        guard let index = config.spaces.firstIndex(where: { $0.folder == space }) else { return }
        let target = index + offset
        guard config.spaces.indices.contains(target) else { return }
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
        return config.spaces.indices.contains(index + offset)
    }

    private func uniqueNewName() -> String {
        let taken = spaces.map(\.folder.rawValue)
        var name = Self.newFolderName
        var number = 2
        while taken.contains(where: { StemPolicy.isSame($0, name) }) {
            name = "\(Self.newFolderName) \(number)"
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

    private func deletedMessage(_ deletion: SpaceDeletion) -> String {
        let name = deletion.space.folder.rawValue
        switch deletion.moves.count {
        case 0: return "Deleted \(name)"
        case 1: return "Deleted \(name). 1 note moved to \(deletion.target.rawValue)."
        default: return "Deleted \(name). \(deletion.moves.count) notes moved to \(deletion.target.rawValue)."
        }
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
