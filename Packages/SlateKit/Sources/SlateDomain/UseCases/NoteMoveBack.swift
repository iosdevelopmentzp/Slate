import Foundation

enum NoteMoveBack {
    static func execute(_ moves: [SpaceDeletion.Move], files: any VaultFileStore, move: MoveNoteUseCase) async throws -> [SpaceDeletion.Move] {
        var restored: [SpaceDeletion.Move] = []
        for moved in moves {
            guard let folder = moved.from.folderPath else { continue }
            guard try await files.meta(moved.to) != nil, try await files.meta(moved.from) == nil else { continue }
            let back = try await move.execute(moved.to, toFolder: folder, stem: moved.from.stem)
            restored.append(SpaceDeletion.Move(from: moved.to, to: back))
        }
        return restored
    }
}
