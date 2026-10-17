import Foundation
import SlateDomain

extension MCPToolRunner {
    func listFolders() async throws -> String {
        let permissions = try await permissions()
        let summaries = try await ports.index.summaries(space: nil)
        let objects: [[String: Any]] = try await folders().map { folder in
            [
                "folder": folder.rawValue,
                "notes": summaries.filter { folder.contains($0.path) }.count,
                "writable": permissions.canWrite(in: folder),
            ]
        }
        return json(objects)
    }

    func listNotes(_ arguments: MCPArguments) async throws -> String {
        var summaries = try await ports.index.summaries(space: nil)
        if let raw = arguments.string("folder") {
            let folder = try await existingFolder(raw)
            summaries = summaries.filter { folder.contains($0.path) }
        }
        let limit = arguments.int("limit", default: 50, maximum: 500)
        let sorted = summaries.sorted { $0.updated > $1.updated }.prefix(limit)
        return json(sorted.map(summaryObject))
    }

    func searchNotes(_ arguments: MCPArguments) async throws -> String {
        let query = try arguments.required("query")
        let folder = try await arguments.string("folder").asyncMap(existingFolder)
        let limit = arguments.int("limit", default: 20, maximum: 200)
        let parsed = SearchQueryParser.parse(query, now: ports.clock.now(), timeZone: ports.clock.timeZone)
        let hits = try await ports.index.search(parsed, limit: folder == nil ? limit : 200)
        let kept = hits.filter { hit in folder.map { $0.contains(hit.summary.path) } ?? true }.prefix(limit)
        return json(kept.map { hit in
            var object = summaryObject(hit.summary)
            object["snippet"] = hit.excerpt
            object["preview"] = nil
            return object
        })
    }

    func readNote(_ arguments: MCPArguments) async throws -> String {
        let path = try await notePath(arguments)
        let contents = try await ports.files.read(path)
        let document = try NoteCodec.decode(contents)
        return json([
            "id": document.id.rawValue,
            "title": document.title,
            "path": path.rawValue,
            "hash": contents.hash.rawValue,
            "text": String(decoding: contents.data, as: UTF8.self),
        ])
    }

    func openInSlate(_ arguments: MCPArguments) async throws -> String {
        let id = try arguments.required("id")
        let document = try await document(at: try await notePath(id: id))
        guard let url = NoteLinkPolicy.openLink(for: document.id) else { throw AgentError.noteNotFound(id) }
        try await open(url)
        return "Slate shows \(document.title)."
    }
}

private extension Optional {
    func asyncMap<T>(_ transform: (Wrapped) async throws -> T) async throws -> T? {
        guard let self else { return nil }
        return try await transform(self)
    }
}
