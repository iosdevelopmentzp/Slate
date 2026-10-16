import Foundation

package struct SpaceDeletion: Hashable, Sendable {
    package struct Move: Hashable, Sendable {
        package let from: VaultPath
        package let to: VaultPath

        package init(from: VaultPath, to: VaultPath) {
            self.from = from
            self.to = to
        }
    }

    package let space: Space
    package let position: Int
    package let target: SpaceName
    package let moves: [Move]

    package init(space: Space, position: Int, target: SpaceName, moves: [Move]) {
        self.space = space
        self.position = position
        self.target = target
        self.moves = moves
    }
}
