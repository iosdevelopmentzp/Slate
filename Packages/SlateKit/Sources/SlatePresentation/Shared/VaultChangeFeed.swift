import Foundation
import SlateDomain

@MainActor
final class VaultChangeFeed {
    private let watcher: any VaultWatching
    private let reindex: ReindexVaultUseCase
    private let activity: ActivityLog
    private let events: AppEvents
    private let agentChanges: any AgentChangeLog
    private let clock: any Clock
    private var task: Task<Void, Never>?
    private var agentsCheckedAt: Date

    init(watcher: any VaultWatching, reindex: ReindexVaultUseCase, activity: ActivityLog, events: AppEvents, agentChanges: any AgentChangeLog, clock: any Clock) {
        self.watcher = watcher
        self.reindex = reindex
        self.activity = activity
        self.events = events
        self.agentChanges = agentChanges
        self.clock = clock
        agentsCheckedAt = clock.now()
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
            await reportAgentChanges()
        case .rescan:
            await scan(.all)
            events.post(.spacesChanged)
            events.post(.vaultRescanned)
        }
    }

    private func reportAgentChanges() async {
        guard let changes = try? await agentChanges.changes(after: agentsCheckedAt), let last = changes.last else { return }
        agentsCheckedAt = last.date
        for change in changes {
            activity.log("Changed by an agent: \(change.title)", detail: change.path.rawValue, outcome: .info)
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
