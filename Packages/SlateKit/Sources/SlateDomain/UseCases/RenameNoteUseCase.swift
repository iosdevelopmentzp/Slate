import Foundation

package struct RenameNoteUseCase: Sendable {
    let files: any VaultFileStore
    let index: any SearchIndex
    let builder: any IndexedNoteBuilding
    let save: SaveNoteUseCase

    package func execute(_ document: NoteDocument, title: String, body: String) async throws -> RenameReport {
        var header = document.header
        header.title = title
        var current = document
        let oldPath = document.path
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
        guard moved else { return RenameReport(result: result) }
        var report = RenameReport(result: result)
        try await rewriteLinks(from: oldPath, to: current.path, id: document.id, into: &report)
        return report
    }

    private func rewriteLinks(from oldPath: VaultPath, to newPath: VaultPath, id: NoteID, into report: inout RenameReport) async throws {
        let renamed = NoteSummary(id: id, path: oldPath, title: oldPath.stem, updated: .distantFuture, preview: "")
        let sameName = try await index.notes(named: oldPath.stem).filter { $0.id != id }
        for linking in try await index.notesLinking(to: oldPath.stem) where linking.id != id {
            do {
                let source = try NoteCodec.decode(try await files.read(linking.path))
                let resolvesHere = WikilinkPolicy.targets(in: source.body).contains { target in
                    WikilinkPolicy.parse(target).stem.lowercased() == oldPath.stem.lowercased()
                        && WikilinkPolicy.resolve(target, candidates: sameName + [renamed], from: source.path)?.id == id
                }
                guard resolvesHere else { continue }
                let body = WikilinkPolicy.rewrite(source.body, from: oldPath.stem, to: newPath.stem)
                guard body != source.body else { continue }
                switch try await save.execute(source, header: source.header, body: body) {
                case .saved, .unchanged:
                    report.rewritten.append(source.path)
                case .conflict:
                    report.failed.append(source.path)
                }
            } catch {
                report.failed.append(linking.path)
            }
        }
    }
}
