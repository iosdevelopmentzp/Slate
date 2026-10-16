import Foundation

package struct ReindexVaultUseCase: Sendable {
    let files: any VaultFileStore
    let index: any SearchIndex
    let builder: any IndexedNoteBuilding

    static let batchSize = 200

    private enum Outcome: Sendable {
        case indexed(IndexedNote)
        case touched(IndexedFileState, VaultPath)
        case failed(VaultPath)
    }

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
        let changed = metas.filter { meta in states[meta.path].map { $0.matches(meta) == false } ?? true }
        var start = 0
        while start < changed.count {
            try Task.checkCancellation()
            let chunk = Array(changed[start..<min(start + Self.batchSize, changed.count)])
            start += Self.batchSize
            var batch: [IndexedNote] = []
            for outcome in try await process(chunk, states: states) {
                switch outcome {
                case .indexed(let note):
                    batch.append(note)
                    report.indexed.append(note.summary.path)
                case .touched(let state, let path):
                    try await index.updateState(state, for: path)
                case .failed(let path):
                    report.failed.append(path)
                }
            }
            if batch.isEmpty == false {
                try await index.upsert(contentsOf: batch)
            }
        }
        return report
    }

    private func process(_ chunk: [FileMeta], states: [VaultPath: IndexedFileState]) async throws -> [Outcome] {
        let files = files
        let builder = builder
        return try await withThrowingTaskGroup(of: (Int, Outcome).self) { group in
            for (position, meta) in chunk.enumerated() {
                let known = states[meta.path]
                group.addTask {
                    do {
                        let contents = try await files.read(meta.path)
                        if let known, known.hash == contents.hash {
                            return (position, .touched(IndexedFileState(modified: contents.meta.modified, size: contents.meta.size, hash: contents.hash), meta.path))
                        }
                        return (position, .indexed(builder.build(try NoteCodec.decode(contents))))
                    } catch is CancellationError {
                        throw CancellationError()
                    } catch {
                        return (position, .failed(meta.path))
                    }
                }
            }
            var outcomes: [(Int, Outcome)] = []
            for try await outcome in group {
                outcomes.append(outcome)
            }
            return outcomes.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }
}
