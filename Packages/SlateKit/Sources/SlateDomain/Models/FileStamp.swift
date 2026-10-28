import Foundation

package struct FileStamp: Hashable, Sendable {
    package var modified: Date
    package var size: Int

    package init(modified: Date, size: Int) {
        self.modified = modified
        self.size = size
    }

    package init(_ meta: FileMeta) {
        self.init(modified: meta.modified, size: meta.size)
    }

    package func matches(_ meta: FileMeta) -> Bool {
        abs(modified.timeIntervalSince(meta.modified)) < 0.001 && size == meta.size
    }
}
