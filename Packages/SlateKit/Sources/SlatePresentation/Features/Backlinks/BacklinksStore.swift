import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class BacklinksStore {
    private(set) var path: VaultPath?
    private(set) var backlinks: [Backlink] = []

    @ObservationIgnored private let load: BacklinksUseCase
    @ObservationIgnored private let navigator: Navigator
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(load: BacklinksUseCase, navigator: Navigator, activity: ActivityLog, events: AppEvents) {
        self.load = load
        self.navigator = navigator
        self.activity = activity
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .indexUpdated, .vaultChanged, .vaultRescanned, .noteMoved, .noteTrashed:
                Task { await self.refresh() }
            case .spacesChanged, .noteCreated, .noteSaved, .searchOpened:
                break
            }
        }
    }

    func show(_ path: VaultPath?) async {
        guard path != self.path else { return }
        self.path = path
        backlinks = []
        await refresh()
    }

    func refresh() async {
        await refreshTask.run { [weak self] in
            guard let self else { return }
            guard let path else { return }
            do {
                let loaded = try await load.execute(for: path)
                try Task.checkCancellation()
                guard path == self.path, loaded != backlinks else { return }
                backlinks = loaded
            } catch is CancellationError {
                return
            } catch {
                activity.log("Cannot find the notes that link here", detail: error.localizedDescription, outcome: .failure)
            }
        }
    }

    func open(_ id: NoteID) {
        navigator.select(id)
    }
}
