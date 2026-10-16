import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class VaultStore {
    static let icons = ["folder", "tray", "checkmark.circle", "note.text", "calendar", "archivebox", "star", "book", "lightbulb", "hammer", "chevron.left.forwardslash.chevron.right", "person.2"]

    var config = SpacesConfig(spaces: [])

    @ObservationIgnored private let repository: any VaultConfigRepository
    @ObservationIgnored private let createSpace: CreateSpaceUseCase
    @ObservationIgnored private let renameSpace: RenameSpaceUseCase
    @ObservationIgnored private let navigator: Navigator
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(
        config: any VaultConfigRepository,
        createSpace: CreateSpaceUseCase,
        renameSpace: RenameSpaceUseCase,
        navigator: Navigator,
        activity: ActivityLog,
        events: AppEvents
    ) {
        repository = config
        self.createSpace = createSpace
        self.renameSpace = renameSpace
        self.navigator = navigator
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

    @discardableResult
    func create(named name: String) async -> Bool {
        do {
            let space = try await createSpace.execute(name: name)
            await refresh()
            navigator.show(.space(space))
            return true
        } catch {
            activity.log("Cannot create the folder", detail: error.localizedDescription, outcome: .failure)
            return false
        }
    }

    @discardableResult
    func rename(_ space: SpaceName, to name: String) async -> Bool {
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
            activity.log("Cannot rename the folder", detail: error.localizedDescription, outcome: .failure)
            return false
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

    func setCaptureSpace(_ space: SpaceName) async {
        var updated = config
        updated.captureSpace = space
        await save(updated)
    }

    func canMove(_ space: SpaceName, by offset: Int) -> Bool {
        guard let index = config.spaces.firstIndex(where: { $0.folder == space }) else { return false }
        return config.spaces.indices.contains(index + offset)
    }

    private func save(_ updated: SpacesConfig) async {
        let previous = config
        config = updated
        do {
            try await repository.saveSpaces(updated)
        } catch {
            config = previous
            activity.log("Cannot save the folder order", detail: error.localizedDescription, outcome: .failure)
        }
    }
}
