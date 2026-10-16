import Foundation

package struct RestoreSpaceUseCase: Sendable {
    let files: any VaultFileStore
    let index: any SearchIndex
    let builder: any IndexedNoteBuilding
    let config: any VaultConfigRepository

    package func execute(_ deletion: SpaceDeletion) async throws -> [SpaceDeletion.Move] {
        try await files.createFolder(deletion.space.folder)
        var spaces = try await config.spaces()
        spaces.spaces.removeAll { $0.folder == deletion.space.folder }
        spaces.spaces.insert(deletion.space, at: min(deletion.position, spaces.spaces.count))
        try await config.saveSpaces(spaces)
        var restored: [SpaceDeletion.Move] = []
        for moved in deletion.moves {
            guard try await files.meta(moved.to) != nil, try await files.meta(moved.from) == nil else { continue }
            try await files.move(from: moved.to, to: moved.from)
            try await index.remove(path: moved.to)
            let document = try NoteCodec.decode(try await files.read(moved.from))
            try await index.upsert(builder.build(document))
            restored.append(SpaceDeletion.Move(from: moved.to, to: moved.from))
        }
        return restored
    }
}
