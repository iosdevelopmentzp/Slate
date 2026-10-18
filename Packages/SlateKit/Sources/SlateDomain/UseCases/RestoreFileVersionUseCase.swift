import Foundation

package struct RestoreFileVersionUseCase: Sendable {
    let history: any HistoryRepository
    let files: any VaultFileStore

    package func execute(_ snapshot: Snapshot, of path: VaultPath) async throws {
        try await history.ensureRepository()
        _ = try await history.snapshot(message: "before restore: \(path.rawValue)")
        let data = try await history.contents(of: path, at: snapshot.hash)
        _ = try await files.write(path, data: data, expected: nil)
    }
}
