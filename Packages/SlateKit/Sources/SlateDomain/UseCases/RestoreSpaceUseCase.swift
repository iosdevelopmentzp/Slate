import Foundation

package struct RestoreSpaceUseCase: Sendable {
    let files: any VaultFileStore
    let config: any VaultConfigRepository
    let move: MoveNoteUseCase

    package func execute(_ deletion: SpaceDeletion) async throws -> [SpaceDeletion.Move] {
        try await files.createFolder(FolderPath(space: deletion.space.folder))
        var spaces = try await config.spaces()
        spaces.spaces.removeAll { $0.folder == deletion.space.folder }
        spaces.spaces.insert(deletion.space, at: min(deletion.position, spaces.spaces.count))
        try await config.saveSpaces(spaces)
        return try await NoteMoveBack.execute(deletion.moves, files: files, move: move)
    }
}
