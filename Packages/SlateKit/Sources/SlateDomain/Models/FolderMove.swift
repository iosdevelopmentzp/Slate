import Foundation

package struct FolderMove: Hashable, Sendable {
    package let from: FolderPath
    package let to: FolderPath
    package let space: Space?
    package let position: Int?

    package init(from: FolderPath, to: FolderPath, space: Space? = nil, position: Int? = nil) {
        self.from = from
        self.to = to
        self.space = space
        self.position = position
    }
}
