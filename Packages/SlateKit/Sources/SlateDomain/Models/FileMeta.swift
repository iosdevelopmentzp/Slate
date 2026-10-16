import Foundation

package struct FileMeta: Hashable, Sendable {
    package let path: VaultPath
    package var created: Date
    package var modified: Date
    package var size: Int

    package init(path: VaultPath, created: Date, modified: Date, size: Int) {
        self.path = path
        self.created = created
        self.modified = modified
        self.size = size
    }
}
