import Foundation

package struct RestoreFolderUseCase: Sendable {
    let files: any VaultFileStore
    let move: MoveNoteUseCase

    package func execute(_ deletion: FolderDeletion) async throws -> [SpaceDeletion.Move] {
        let wanted = Set(([deletion.folder] + deletion.moves.compactMap(\.from.folderPath)).filter { $0.isSpace == false })
        for folder in wanted.sorted(by: { $0.depth < $1.depth }) {
            if try await files.folders().contains(folder) == false {
                try await files.createFolder(folder)
            }
        }
        return try await NoteMoveBack.execute(deletion.moves, files: files, move: move)
    }
}
