import Foundation

package struct SaveVersionUseCase: Sendable {
    let history: any HistoryRepository
    let keyValues: any KeyValueStore
    let snapshot: SnapshotHistoryUseCase

    package func execute(name: String) async throws -> Bool {
        let message = Snapshot.versionPrefix + name
        guard try await snapshot.execute(push: false, message: message).committed == false else { return true }
        let settings = HistorySettings.load(from: keyValues)
        guard settings.isEnabled, await history.isAvailable(), let last = try await history.lastSnapshot(), last.isByAgent else { return false }
        let pushed = await history.lastPushedHash()
        guard pushed != last.hash, pushed != nil || settings.hasRemote == false else { return false }
        try await history.renameLastSnapshot(to: message)
        return true
    }
}
