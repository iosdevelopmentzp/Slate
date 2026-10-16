import Foundation

package protocol HistoryRepository: Sendable {
    func isAvailable() async -> Bool
    func ensureRepository() async throws
    func snapshot(message: String?) async throws -> Bool
    func history(of path: VaultPath) async throws -> [Snapshot]
    func contents(of path: VaultPath, at hash: String) async throws -> Data
    func push(to remote: String) async throws
    func lastSnapshot() async throws -> Snapshot?
}
