import Foundation

package struct TrashItem: Identifiable, Hashable, Sendable {
    package let path: VaultPath
    package var originalPath: VaultPath
    package var trashedAt: Date

    package var id: VaultPath {
        path
    }

    package init(path: VaultPath, originalPath: VaultPath, trashedAt: Date) {
        self.path = path
        self.originalPath = originalPath
        self.trashedAt = trashedAt
    }
}
