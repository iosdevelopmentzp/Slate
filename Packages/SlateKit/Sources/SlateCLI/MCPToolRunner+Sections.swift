import Foundation
import SlateDomain

extension MCPToolRunner {
    func readSection(_ arguments: MCPArguments) async throws -> String {
        let heading = try arguments.required("heading")
        let path = try await notePath(arguments)
        let contents = try await ports.files.read(path)
        let document = try NoteCodec.decode(contents)
        guard let text = NoteSectionPolicy.text(of: heading, in: document.body) else {
            throw AgentError.noSection(heading, headings: NoteSectionPolicy.headings(in: document.body))
        }
        return json([
            "id": document.id.rawValue,
            "path": path.rawValue,
            "heading": heading,
            "text": text,
            "hash": contents.hash.rawValue,
        ])
    }

    func updateSection(_ arguments: MCPArguments) async throws -> String {
        let heading = try arguments.required("heading")
        guard let text = arguments.raw("text") else { throw AgentError.missingArgument("text") }
        let saved = try await rewrite("update_section", arguments) { body in
            NoteSectionPolicy.replacing(heading, with: text, in: body)
        }
        return written(saved)
    }

    func replaceInNote(_ arguments: MCPArguments) async throws -> String {
        guard let old = arguments.raw("old"), old.isEmpty == false else { throw AgentError.missingArgument("old") }
        guard let new = arguments.raw("new") else { throw AgentError.missingArgument("new") }
        let saved = try await rewrite("replace_in_note", arguments) { body in
            try TextReplacePolicy.replacing(old, with: new, in: body)
        }
        return written(saved)
    }

    func prependToNote(_ arguments: MCPArguments) async throws -> NoteDocument {
        let text = try arguments.required("text")
        let section = arguments.string("section")
        return try await rewrite("append_to_note", arguments) { body in
            NoteSectionPolicy.prepend(text, toSection: section, in: body)
        }
    }

    func listBacklinks(_ arguments: MCPArguments) async throws -> String {
        let path = try await notePath(arguments)
        let summaries = try await ports.index.notesLinking(to: path.stem)
        return json(summaries.filter { $0.path != path }.map(summaryObject))
    }

    func written(_ document: NoteDocument) -> String {
        json(["id": document.id.rawValue, "path": document.path.rawValue, "hash": document.hash.rawValue])
    }

    private func rewrite(_ tool: String, _ arguments: MCPArguments, change: (String) throws -> String) async throws -> NoteDocument {
        let path = try await notePath(id: try arguments.required("id"))
        try await permissions().checkWrite(path)
        let expected = arguments.string("expectedHash")
        var didSnapshot = false
        for _ in 0..<3 {
            let current = try await document(at: path)
            if let expected, current.hash.rawValue != expected { throw AgentError.staleNote }
            let body = try change(current.body)
            if didSnapshot == false {
                await beforeWrite()
                didSnapshot = true
            }
            if let saved = try await useCases.save.execute(current, header: current.header, body: body).document {
                await afterWrite(tool, title: saved.title, path: saved.path)
                return saved
            }
            if expected != nil { throw AgentError.staleNote }
        }
        throw AgentError.staleNote
    }
}
