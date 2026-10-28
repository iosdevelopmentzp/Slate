import Foundation
import SlateDomain

extension MCPToolRunner {
    func readFile(_ arguments: MCPArguments) async throws -> String {
        let path = try AgentPathPolicy.filePath(from: try arguments.required("path"), root: root)
        guard let meta = try await ports.files.meta(path) else { throw VaultError.notFound(path) }
        var answer: [String: Any] = [
            "name": path.fileName,
            "path": path.rawValue,
            "absolutePath": root.appendingPathComponent(path.rawValue).path,
            "size": meta.size,
            "modified": ISO8601DateFormatter().string(from: meta.modified),
            "kind": "other",
        ]
        if FileKindPolicy.mayBeText(path, size: meta.size) {
            let contents = try await ports.files.read(path)
            if let text = FileKindPolicy.text(from: contents.data) {
                answer["kind"] = "text"
                answer["text"] = text
                answer["hash"] = contents.hash.rawValue
            }
        } else if FileIndexPolicy.isPDF(path), FileIndexPolicy.readsContent(path, size: meta.size) {
            let contents = try await ports.files.read(path)
            answer["kind"] = "pdf"
            answer["text"] = ports.builder.text(ofFile: path, data: contents.data).map(FileIndexPolicy.trimmed) ?? ""
        }
        return json(answer)
    }

    func replaceInFile(_ arguments: MCPArguments) async throws -> String {
        let old = try arguments.required("old")
        guard let new = arguments.raw("new") else { throw AgentError.missingArgument("new") }
        return try await writeFile("replace_in_file", arguments, expected: arguments.string("expectedHash")) { text in
            try TextReplacePolicy.replacing(old, with: new, in: text)
        }
    }

    func updateFile(_ arguments: MCPArguments) async throws -> String {
        guard let text = arguments.raw("text") else { throw AgentError.missingArgument("text") }
        let expected = try arguments.required("expectedHash")
        return try await writeFile("update_file", arguments, expected: expected) { _ in text }
    }

    func trashFile(_ arguments: MCPArguments) async throws -> String {
        let path = try AgentPathPolicy.filePath(from: try arguments.required("path"), root: root)
        try await permissions().checkTrash(path)
        await beforeWrite()
        _ = try await ports.files.trashFile(path)
        await afterWrite("trash_file", title: path.fileName, path: path)
        return "Moved \(path.fileName) to the macOS Trash. The owner can put it back from there."
    }

    private func writeFile(_ tool: String, _ arguments: MCPArguments, expected: String?, change: (String) throws -> String) async throws -> String {
        let path = try AgentPathPolicy.filePath(from: try arguments.required("path"), root: root)
        try await permissions().checkWrite(path)
        await beforeWrite()
        let hash = try await useCases.writeTextFile.execute(path, expected: expected.map(ContentHash.init(rawValue:)), change: change)
        await afterWrite(tool, title: path.fileName, path: path)
        return json(["path": path.rawValue, "hash": hash.rawValue])
    }
}
