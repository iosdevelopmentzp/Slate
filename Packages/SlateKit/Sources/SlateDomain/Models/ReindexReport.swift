import Foundation

package struct ReindexReport: Hashable, Sendable {
    package var indexed: [VaultPath]
    package var removed: [VaultPath]
    package var failed: [VaultPath]

    package var changed: [VaultPath] {
        indexed + removed
    }

    package init(indexed: [VaultPath] = [], removed: [VaultPath] = [], failed: [VaultPath] = []) {
        self.indexed = indexed
        self.removed = removed
        self.failed = failed
    }
}
