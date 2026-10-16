import Foundation

package struct PurgeTrashUseCase: Sendable {
    let trash: any TrashRepository
    let keyValues: any KeyValueStore
    let clock: any Clock

    package static let retentionKey = "trash.retentionDays"

    package func execute() async throws -> Int {
        let stored = keyValues.integer(forKey: Self.retentionKey)
        let days = stored > 0 ? stored : 30
        let due = TrashRetentionPolicy.due(try await trash.items(), now: clock.now(), days: days)
        for item in due {
            try await trash.delete(item)
        }
        return due.count
    }
}
