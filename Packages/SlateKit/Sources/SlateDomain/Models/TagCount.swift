import Foundation

package struct TagCount: Hashable, Sendable {
    package var tag: String
    package var count: Int

    package init(tag: String, count: Int) {
        self.tag = tag
        self.count = count
    }
}
