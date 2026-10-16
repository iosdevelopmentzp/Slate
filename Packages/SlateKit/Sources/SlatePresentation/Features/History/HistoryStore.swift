import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class HistoryStore {
    static let purgeInterval: Duration = .seconds(86_400)

    var settings: HistorySettings
    private(set) var snapshots: [Snapshot] = []
    private(set) var isLoading = false
    private(set) var lastSnapshot: Date?
    private(set) var push: SnapshotOutcome.Push = .notConfigured
    private(set) var isSnapshotting = false
    private(set) var isAvailable = true

    @ObservationIgnored private let history: any HistoryRepository
    @ObservationIgnored private let snapshot: SnapshotHistoryUseCase
    @ObservationIgnored private let restoreVersion: RestoreVersionUseCase
    @ObservationIgnored private let purgeTrash: PurgeTrashUseCase
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let toaster: Toaster
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private var snapshotLoop: Task<Void, Never>?
    @ObservationIgnored private var purgeLoop: Task<Void, Never>?

    init(
        history: any HistoryRepository,
        snapshot: SnapshotHistoryUseCase,
        restoreVersion: RestoreVersionUseCase,
        purgeTrash: PurgeTrashUseCase,
        store: any KeyValueStore,
        activity: ActivityLog,
        toaster: Toaster,
        events: AppEvents
    ) {
        self.history = history
        self.snapshot = snapshot
        self.restoreVersion = restoreVersion
        self.purgeTrash = purgeTrash
        self.store = store
        self.activity = activity
        self.toaster = toaster
        self.events = events
        settings = HistorySettings.load(from: store)
    }

    func start() {
        Task {
            isAvailable = await history.isAvailable()
            lastSnapshot = try? await history.lastSnapshot()?.date
            await snapshotNow()
        }
        restartLoop()
        purgeLoop?.cancel()
        purgeLoop = Task { [weak self] in
            while Task.isCancelled == false {
                guard let self else { return }
                await purgeNow()
                try? await Task.sleep(for: Self.purgeInterval)
            }
        }
    }

    func stop() {
        snapshotLoop?.cancel()
        purgeLoop?.cancel()
    }

    func saveSettings() {
        settings.save(to: store)
        restartLoop()
    }

    func setRemote(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != settings.remote else { return }
        settings.remote = trimmed
        saveSettings()
    }

    func backUpNow() async {
        guard settings.hasRemote else {
            toaster.show("Add a git address to back up to.")
            return
        }
        await snapshotNow(push: true)
        switch push {
        case .pushed: toaster.show("Backed up")
        case .failed: toaster.show("The backup failed. See Activity in Settings.")
        case .notConfigured: break
        }
    }

    func snapshotNow(push: Bool = true) async {
        guard settings.isEnabled, isSnapshotting == false else { return }
        isSnapshotting = true
        defer { isSnapshotting = false }
        do {
            let outcome = try await snapshot.execute(push: push)
            if outcome.committed {
                lastSnapshot = (try? await history.lastSnapshot()?.date) ?? Date()
            }
            self.push = outcome.push
            if case .failed(let message) = outcome.push {
                activity.log("Push of the history failed", detail: message, outcome: .failure)
            }
        } catch {
            activity.log("Cannot save a version", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func load(for path: VaultPath?) async {
        guard let path else {
            snapshots = []
            return
        }
        isLoading = true
        defer { isLoading = false }
        snapshots = (try? await history.history(of: path)) ?? []
    }

    func restore(_ snapshot: Snapshot, of path: VaultPath) async {
        do {
            switch try await restoreVersion.execute(snapshot, of: path) {
            case .saved, .unchanged:
                events.post(.vaultChanged([path]))
                events.post(.indexUpdated)
                toaster.show("Restored the earlier version")
                await load(for: path)
            case .conflict:
                toaster.show("The note changed while restoring. Try again.")
            }
        } catch {
            activity.log("Cannot restore the version", detail: error.localizedDescription, outcome: .failure)
            toaster.show("The version was not restored. See Activity in Settings.")
        }
    }

    func purgeNow() async {
        do {
            let count = try await purgeTrash.execute()
            if count > 0 {
                activity.log("Emptied old notes from the Trash", detail: count == 1 ? "1 note" : "\(count) notes", outcome: .success)
            }
        } catch {
            activity.log("Cannot empty the Trash", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func quitJob() -> (@Sendable () async -> Void)? {
        guard settings.isEnabled else { return nil }
        let snapshot = snapshot
        let push = settings.pushOnQuit
        return {
            _ = try? await snapshot.execute(push: push)
        }
    }

    private func restartLoop() {
        snapshotLoop?.cancel()
        guard settings.isEnabled else { return }
        let interval = Duration.seconds(max(settings.intervalMinutes, 1) * 60)
        snapshotLoop = Task { [weak self] in
            while Task.isCancelled == false {
                try? await Task.sleep(for: interval)
                guard Task.isCancelled == false, let self else { return }
                await snapshotNow()
            }
        }
    }
}
