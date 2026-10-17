import Foundation

package struct DeleteFolderUseCase: Sendable {
    let files: any VaultFileStore
    let move: MoveNoteUseCase

    package func execute(_ folder: FolderPath) async throws -> FolderDeletion {
        guard let parent = folder.parent else { throw VaultError.notFound(VaultPath(rawValue: folder.rawValue)) }
        let notes = try await files.enumerate().map(\.path).filter { $0.isNote && folder.contains($0) }
        var moves: [SpaceDeletion.Move] = []
        for path in notes.sorted(by: { $0.rawValue < $1.rawValue }) {
            moves.append(SpaceDeletion.Move(from: path, to: try await move.execute(path, toFolder: parent)))
        }
        try await files.removeFolder(folder)
        return FolderDeletion(folder: folder, target: parent, moves: moves)
    }
}
