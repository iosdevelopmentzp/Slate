import Foundation
import SlateDomain

@MainActor
final class VaultChangeFeed {
    private let watcher: any VaultWatching
    private let reindex: ReindexVaultUseCase
    private let activity: ActivityLog
    private let events: AppEvents
    private var task: Task<Void, Never>?

    init(watcher: any VaultWatching, reindex: ReindexVaultUseCase, activity: ActivityLog, events: AppEvents) {
        self.watcher = watcher
        self.reindex = reindex
        self.activity = activity
        self.events = events
    }

    func start() {
        guard task == nil else { return }
        let changes = watcher.changes()
        task = Task { [weak self] in
            guard let self else { return }
            await scan(.all)
            for await change in changes {
                guard Task.isCancelled == false else { return }
                await apply(change)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    func apply(_ change: VaultChange) async {
        switch change {
        case .paths(let paths):
            await scan(.paths(paths))
            events.post(.vaultChanged(paths))
        case .rescan:
            await scan(.all)
            events.post(.spacesChanged)
            events.post(.vaultRescanned)
        }
    }

    private func scan(_ scope: ReindexScope) async {
        do {
            let report = try await reindex.execute(scope)
            for path in report.failed {
                activity.log("Cannot read a note", detail: path.rawValue, outcome: .failure)
            }
            if scope == .all || report.changed.isEmpty == false {
                events.post(.indexUpdated)
            }
        } catch is CancellationError {
            return
        } catch {
            activity.log("Cannot read the notes folder", detail: error.localizedDescription, outcome: .failure)
        }
    }
}
