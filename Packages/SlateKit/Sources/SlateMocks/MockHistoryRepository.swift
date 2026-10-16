import Foundation
import SlateDomain

struct MockHistoryRepository: HistoryRepository {
    func isAvailable() async -> Bool {
        true
    }

    func ensureRepository() async throws {}

    func snapshot(message: String?) async throws -> Bool {
        false
    }

    func history(of path: VaultPath) async throws -> [Snapshot] {
        [
            Snapshot(hash: "a1b2c3d", date: MockVault.reference.addingTimeInterval(-3_600), message: "snapshot: 2 files"),
            Snapshot(hash: "d4e5f6a", date: MockVault.reference.addingTimeInterval(-86_400 * 2), message: "snapshot: 5 files"),
        ]
    }

    func contents(of path: VaultPath, at hash: String) async throws -> Data {
        Data()
    }

    func push(to remote: String) async throws {}

    func lastSnapshot() async throws -> Snapshot? {
        Snapshot(hash: "a1b2c3d", date: MockVault.reference.addingTimeInterval(-600), message: "snapshot: 2 files")
    }
}
