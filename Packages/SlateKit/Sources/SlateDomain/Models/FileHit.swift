import Foundation

package struct FileHit: Identifiable, Hashable, Sendable {
    package let path: VaultPath
    package var excerpt: String
    package var rank: Double

    package var id: VaultPath {
        path
    }

    package init(path: VaultPath, excerpt: String, rank: Double) {
        self.path = path
        self.excerpt = excerpt
        self.rank = rank
    }
}
