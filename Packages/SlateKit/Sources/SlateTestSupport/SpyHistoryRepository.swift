import Foundation
import SlateDomain

package final class SpyHistoryRepository: HistoryRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case ensure
        case snapshot(String?)
        case history(VaultPath)
        case contents(VaultPath, String)
        case push(String)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _available = true
    private var _hasChanges = true
    private var _snapshots: [VaultPath: [Snapshot]] = [:]
    private var _contents: [String: Data] = [:]
    private var _pushError: TestError?

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var available: Bool {
        get { lock.withLock { _available } }
        set { lock.withLock { _available = newValue } }
    }

    package var hasChanges: Bool {
        get { lock.withLock { _hasChanges } }
        set { lock.withLock { _hasChanges = newValue } }
    }

    package var pushError: TestError? {
        get { lock.withLock { _pushError } }
        set { lock.withLock { _pushError = newValue } }
    }

    package func seed(_ snapshot: Snapshot, of path: VaultPath, text: String) {
        lock.withLock {
            _snapshots[path, default: []].insert(snapshot, at: 0)
            _contents["\(snapshot.hash):\(path.rawValue)"] = Data(text.utf8)
        }
    }

    package func isAvailable() async -> Bool {
        available
    }

    package func ensureRepository() async throws {
        lock.withLock { _calls.append(.ensure) }
    }

    package func snapshot(message: String?) async throws -> Bool {
        lock.withLock {
            _calls.append(.snapshot(message))
            return _hasChanges
        }
    }

    package func history(of path: VaultPath) async throws -> [Snapshot] {
        lock.withLock {
            _calls.append(.history(path))
            return _snapshots[path] ?? []
        }
    }

    package func contents(of path: VaultPath, at hash: String) async throws -> Data {
        try lock.withLock {
            _calls.append(.contents(path, hash))
            guard let data = _contents["\(hash):\(path.rawValue)"] else { throw TestError.scripted("no contents") }
            return data
        }
    }

    package func push(to remote: String) async throws {
        try lock.withLock {
            _calls.append(.push(remote))
            if let _pushError { throw _pushError }
        }
    }

    package func lastSnapshot() async throws -> Snapshot? {
        lock.withLock { _snapshots.values.flatMap { $0 }.max { $0.date < $1.date } }
    }
}
