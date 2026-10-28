import Foundation
import SlateDomain

package final class SpyHistoryRepository: HistoryRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case ensure
        case snapshot(String?)
        case history(VaultPath)
        case contents(VaultPath, String)
        case push(String)
        case changes(FolderPath?)
        case clear(FolderPath?)
        case rename(String)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _available = true
    private var _hasChanges = true
    private var _snapshots: [VaultPath: [Snapshot]] = [:]
    private var _contents: [String: Data] = [:]
    private var _pushError: TestError?
    private var _changes: [SnapshotChange] = []
    private var _pushedHash: String?

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

    package var pushedHash: String? {
        get { lock.withLock { _pushedHash } }
        set { lock.withLock { _pushedHash = newValue } }
    }

    package func seed(_ snapshot: Snapshot, of path: VaultPath, text: String) {
        lock.withLock {
            _snapshots[path, default: []].insert(snapshot, at: 0)
            _contents["\(snapshot.hash):\(path.rawValue)"] = Data(text.utf8)
        }
    }

    package var changeList: [SnapshotChange] {
        get { lock.withLock { _changes } }
        set { lock.withLock { _changes = newValue } }
    }

    package func changes(in folder: FolderPath?, limit: Int) async throws -> [SnapshotChange] {
        lock.withLock {
            _calls.append(.changes(folder))
            return Array(_changes.prefix(limit))
        }
    }

    package func clear(_ folder: FolderPath?) async throws {
        lock.withLock {
            _calls.append(.clear(folder))
            if let folder {
                for path in _snapshots.keys where folder.contains(path) {
                    _snapshots[path] = []
                }
            } else {
                _snapshots = [:]
            }
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

    package func canReach(_ remote: String) async -> Bool {
        lock.withLock { _pushError == nil }
    }

    package func lastSnapshot() async throws -> Snapshot? {
        lock.withLock { _snapshots.values.flatMap { $0 }.max { $0.date < $1.date } }
    }

    package func renameLastSnapshot(to message: String) async throws {
        lock.withLock { _calls.append(.rename(message)) }
    }

    package func lastPushedHash() async -> String? {
        pushedHash
    }
}
