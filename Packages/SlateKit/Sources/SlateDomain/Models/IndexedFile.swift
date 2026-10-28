import Foundation

package struct IndexedFile: Hashable, Sendable {
    package let path: VaultPath
    package var stamp: FileStamp
    package var text: String

    package init(path: VaultPath, stamp: FileStamp, text: String) {
        self.path = path
        self.stamp = stamp
        self.text = text
    }
}
