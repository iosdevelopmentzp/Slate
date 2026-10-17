import Foundation

package struct DeleteSpaceUseCase: Sendable {
    let files: any VaultFileStore
    let config: any VaultConfigRepository
    let move: MoveNoteUseCase

    package func execute(_ name: SpaceName) async throws -> SpaceDeletion {
        var spaces = try await config.spaces()
        guard name != spaces.captureSpace else { throw VaultError.defaultFolder(name.rawValue) }
        guard let position = spaces.spaces.firstIndex(where: { $0.folder == name }) else { throw VaultError.notFound(VaultPath(rawValue: name.rawValue)) }
        let space = spaces.spaces[position]
        let notes = try await files.enumerate().map(\.path).filter { $0.space == name && $0.isNote }
        var moves: [SpaceDeletion.Move] = []
        for path in notes.sorted(by: { $0.rawValue < $1.rawValue }) {
            moves.append(SpaceDeletion.Move(from: path, to: try await move.execute(path, to: spaces.captureSpace)))
        }
        try await files.removeFolder(FolderPath(space: name))
        spaces.spaces.remove(at: position)
        if spaces.archiveSpace == name { spaces.archiveSpace = spaces.captureSpace }
        try await config.saveSpaces(spaces)
        return SpaceDeletion(space: space, position: position, target: spaces.captureSpace, moves: moves)
    }
}
