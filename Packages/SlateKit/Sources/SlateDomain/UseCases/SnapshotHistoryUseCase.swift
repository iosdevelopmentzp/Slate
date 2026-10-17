import Foundation

package struct SnapshotHistoryUseCase: Sendable {
    let history: any HistoryRepository
    let keyValues: any KeyValueStore

    package func execute(push: Bool = true, message: String? = nil) async throws -> SnapshotOutcome {
        let settings = HistorySettings.load(from: keyValues)
        guard settings.isEnabled, await history.isAvailable() else { return SnapshotOutcome(committed: false, push: .notConfigured) }
        try await history.ensureRepository()
        let committed = try await history.snapshot(message: message)
        guard push, settings.hasRemote else { return SnapshotOutcome(committed: committed, push: .notConfigured) }
        do {
            try await history.push(to: settings.remote.trimmingCharacters(in: .whitespaces))
            return SnapshotOutcome(committed: committed, push: .pushed)
        } catch {
            return SnapshotOutcome(committed: committed, push: .failed(error.localizedDescription))
        }
    }
}
