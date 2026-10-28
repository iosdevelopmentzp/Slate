import Foundation

package struct ReindexVaultUseCase: Sendable {
    let files: any VaultFileStore
    let index: any SearchIndex
    let builder: any IndexedNoteBuilding

    static let batchSize = 200
    static let fileBatchSize = 16

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
        report.files = try await reindexFiles(scope)
        return report
    }

    private func reindexFiles(_ scope: ReindexScope) async throws -> [VaultPath] {
        let stamps = try await index.fileStamps()
        var changed: [VaultPath] = []
        var metas: [FileMeta] = []
        switch scope {
        case .all:
            metas = try await files.enumerateFiles().filter { FileIndexPolicy.isIndexed($0.path) }
            let present = Set(metas.map(\.path))
            for path in stamps.keys where present.contains(path) == false {
                try await index.removeFile(path: path)
                changed.append(path)
            }
        case .paths(let paths):
            let wanted = paths.filter(FileIndexPolicy.isIndexed)
            var listed: [VaultPath: FileMeta] = [:]
            for folder in Set(wanted.map(\.folder)) {
                for meta in try await files.files(in: FolderPath(rawValue: folder)) {
                    listed[meta.path] = meta
                }
            }
            for path in wanted {
                if let meta = listed[path] {
                    metas.append(meta)
                } else if stamps[path] != nil {
                    try await index.removeFile(path: path)
                    changed.append(path)
                }
            }
        }
        let stale = metas.filter { meta in stamps[meta.path].map { $0.matches(meta) == false } ?? true }
        var start = 0
        while start < stale.count {
            try Task.checkCancellation()
            let chunk = Array(stale[start..<min(start + Self.fileBatchSize, stale.count)])
            start += Self.fileBatchSize
            try await index.upsert(files: try await extract(chunk))
            changed += chunk.map(\.path)
        }
        return changed
    }

    private func extract(_ chunk: [FileMeta]) async throws -> [IndexedFile] {
        let files = files
        let builder = builder
        return try await withThrowingTaskGroup(of: (Int, IndexedFile).self) { group in
            for (position, meta) in chunk.enumerated() {
                group.addTask {
                    try Task.checkCancellation()
                    var text = ""
                    if FileIndexPolicy.readsContent(meta.path, size: meta.size), let contents = try? await files.read(meta.path) {
                        text = builder.text(ofFile: meta.path, data: contents.data).map(FileIndexPolicy.trimmed) ?? ""
                    }
                    return (position, IndexedFile(path: meta.path, stamp: FileStamp(meta), text: text))
                }
            }
            var indexed: [(Int, IndexedFile)] = []
            for try await item in group {
                indexed.append(item)
            }
            return indexed.sorted { $0.0 < $1.0 }.map(\.1)
        }
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
