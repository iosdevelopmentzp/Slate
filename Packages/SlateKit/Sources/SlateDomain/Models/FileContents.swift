import Foundation

package struct FileContents: Hashable, Sendable {
    package let data: Data
    package let hash: ContentHash
    package let meta: FileMeta

    package init(data: Data, hash: ContentHash, meta: FileMeta) {
        self.data = data
        self.hash = hash
        self.meta = meta
    }
}
