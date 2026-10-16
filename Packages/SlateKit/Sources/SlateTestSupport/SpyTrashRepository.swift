import Foundation
import SlateDomain

package final class SpyTrashRepository: TrashRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case trash(VaultPath)
        case restore(VaultPath)
        case delete(VaultPath)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _items: [TrashItem] = []
    private let files: SpyVaultFileStore

    package init(files: SpyVaultFileStore) {
        self.files = files
    }

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package func trash(_ path: VaultPath, at date: Date) async throws -> TrashItem {
        let trashed = VaultPath(rawValue: ".trash/\(path.rawValue)")
        try await files.move(from: path, to: trashed)
        let item = TrashItem(path: VaultPath(rawValue: path.rawValue), originalPath: path, trashedAt: date)
        lock.withLock {
            _calls.append(.trash(path))
            _items.append(item)
        }
        return item
    }

    package func restore(_ item: TrashItem) async throws -> VaultPath {
        try await files.move(from: VaultPath(rawValue: ".trash/\(item.path.rawValue)"), to: item.originalPath)
        lock.withLock {
            _calls.append(.restore(item.path))
            _items.removeAll { $0.path == item.path }
        }
        return item.originalPath
    }

    package func delete(_ item: TrashItem) async throws {
        lock.withLock {
            _calls.append(.delete(item.path))
            _items.removeAll { $0.path == item.path }
        }
    }

    package func seed(_ item: TrashItem) {
        lock.withLock { _items.append(item) }
    }

    package func items() async throws -> [TrashItem] {
        lock.withLock { _items }
    }
}
