import Foundation

package struct IndexedFileState: Hashable, Sendable {
    package var modified: Date
    package var size: Int
    package var hash: ContentHash

    package init(modified: Date, size: Int, hash: ContentHash) {
        self.modified = modified
        self.size = size
        self.hash = hash
    }

    package func matches(_ meta: FileMeta) -> Bool {
        abs(modified.timeIntervalSince(meta.modified)) < 0.001 && size == meta.size
    }
}
