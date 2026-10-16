import Foundation

package struct RenameNoteUseCase: Sendable {
    let files: any VaultFileStore
    let index: any SearchIndex
    let builder: any IndexedNoteBuilding
    let save: SaveNoteUseCase

    package func execute(_ document: NoteDocument, title: String, body: String) async throws -> SaveResult {
        var header = document.header
        header.title = title
        var current = document
        var moved = false
        let stem = StemPolicy.stem(forTitle: title)
        if current.type != NoteType.daily.name, StemPolicy.isSame(stem, current.path.stem) == false {
            let stems = try await NoteStems.stems(inFolder: current.path.folder, files: files, excluding: current.path)
            let target = current.path.replacingStem(with: StemPolicy.unique(stem, among: stems))
            try await files.move(from: current.path, to: target)
            try await index.remove(path: current.path)
            current.path = target
            current.meta = FileMeta(path: target, created: current.meta.created, modified: current.meta.modified, size: current.meta.size)
            moved = true
        }
        let result = try await save.execute(current, header: header, body: body)
        if moved, case .unchanged(let unchanged) = result {
            try await index.upsert(builder.build(unchanged))
        }
        return result
    }
}
