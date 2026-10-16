import Foundation

package struct ReindexVaultUseCase: Sendable {
    let files: any VaultFileStore
    let index: any SearchIndex
    let builder: any IndexedNoteBuilding

    @concurrent
    package func execute(_ scope: ReindexScope) async throws -> ReindexReport {
        let states = try await index.fileStates()
        var report = ReindexReport()
        var metas: [FileMeta] = []
        switch scope {
        case .all:
            metas = try await files.enumerate()
            let present = Set(metas.map(\.path))
            for path in states.keys where present.contains(path) == false {
                try await index.remove(path: path)
                report.removed.append(path)
            }
        case .paths(let paths):
            for path in paths where path.isNote {
                if let meta = try await files.meta(path) {
                    metas.append(meta)
                } else if states[path] != nil {
                    try await index.remove(path: path)
                    report.removed.append(path)
                }
            }
        }
        for meta in metas {
            try Task.checkCancellation()
            let known = states[meta.path]
            if let known, known.matches(meta) { continue }
            do {
                let contents = try await files.read(meta.path)
                if let known, known.hash == contents.hash {
                    try await index.updateState(IndexedFileState(modified: contents.meta.modified, size: contents.meta.size, hash: contents.hash), for: meta.path)
                    continue
                }
                try await index.upsert(builder.build(try NoteCodec.decode(contents)))
                report.indexed.append(meta.path)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                report.failed.append(meta.path)
            }
        }
        return report
    }
}
