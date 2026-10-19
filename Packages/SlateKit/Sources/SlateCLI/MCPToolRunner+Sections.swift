import Foundation
import SlateDomain

extension MCPToolRunner {
    static let maxBatch = 50

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
        written(try await rewrite("update_section", arguments))
    }

    func replaceInNote(_ arguments: MCPArguments) async throws -> String {
        written(try await rewrite("replace_in_note", arguments))
    }

    func prependToNote(_ arguments: MCPArguments) async throws -> NoteDocument {
        try await rewrite("append_to_note", arguments)
    }

    func setPlanItem(_ arguments: MCPArguments) async throws -> String {
        let saved = try await rewrite("set_plan_item", arguments)
        var answer: [String: Any] = ["id": saved.id.rawValue, "path": saved.path.rawValue, "hash": saved.hash.rawValue]
        answer["plan"] = planObject(PlanPolicy.items(in: saved.body), withSteps: true)
        return json(answer)
    }

    func batchEdit(_ arguments: MCPArguments) async throws -> String {
        let operations = arguments.objects("operations")
        guard operations.isEmpty == false else { throw AgentError.missingArgument("operations") }
        guard operations.count <= Self.maxBatch else { throw AgentError.batchTooLarge }
        let permissions = try await permissions()
        var order: [VaultPath] = []
        var notes: [VaultPath: (document: NoteDocument, body: String)] = [:]
        for (offset, operation) in operations.enumerated() {
            do {
                let change = try bodyChange(try operation.required("tool"), operation)
                let path = try await target(of: operation)
                try permissions.checkWrite(path)
                if notes[path] == nil {
                    let document = try await document(at: path)
                    notes[path] = (document, document.body)
                    order.append(path)
                }
                guard let note = notes[path] else { continue }
                if let expected = operation.string("expectedHash"), note.document.hash.rawValue != expected { throw AgentError.staleNote }
                notes[path] = (note.document, try change(note.body))
            } catch {
                throw AgentError.batchStep(offset + 1, error.localizedDescription)
            }
        }
        await beforeWrite()
        var done: [[String: Any]] = []
        for path in order {
            guard let note = notes[path] else { continue }
            guard let saved = try await useCases.save.execute(note.document, header: note.document.header, body: note.body).document else {
                throw AgentError.batchConflict(path.rawValue, written: done.compactMap { $0["path"] as? String })
            }
            await record("batch_edit", title: saved.title, path: saved.path)
            done.append(["id": saved.id.rawValue, "path": saved.path.rawValue, "hash": saved.hash.rawValue])
        }
        await snapshot("agent: batch_edit \(order.count == 1 ? notes[order[0]]?.document.title ?? "1 note" : "\(order.count) notes")")
        return json(["operations": operations.count, "notes": done])
    }

    func listBacklinks(_ arguments: MCPArguments) async throws -> String {
        let path = try await notePath(arguments)
        let summaries = try await ports.index.notesLinking(to: path.stem)
        return json(summaries.filter { $0.path != path }.map(summaryObject))
    }

    func written(_ document: NoteDocument) -> String {
        json(["id": document.id.rawValue, "path": document.path.rawValue, "hash": document.hash.rawValue])
    }

    func planObject(_ items: [PlanItem], withSteps: Bool) -> [String: Any]? {
        guard items.isEmpty == false else { return nil }
        var object: [String: Any] = ["done": items.filter(\.isDone).count, "total": items.count]
        object["next"] = items.first { $0.isDone == false }?.label
        if withSteps {
            object["steps"] = items.map { ["number": $0.number, "text": $0.text, "done": $0.isDone] as [String: Any] }
        }
        return object
    }

    private func bodyChange(_ tool: String, _ arguments: MCPArguments) throws -> (String) throws -> String {
        switch tool {
        case "replace_in_note":
            guard let old = arguments.raw("old"), old.isEmpty == false else { throw AgentError.missingArgument("old") }
            guard let new = arguments.raw("new") else { throw AgentError.missingArgument("new") }
            return { try TextReplacePolicy.replacing(old, with: new, in: $0) }
        case "update_section":
            let heading = try arguments.required("heading")
            guard let text = arguments.raw("text") else { throw AgentError.missingArgument("text") }
            return { NoteSectionPolicy.replacing(heading, with: text, in: $0) }
        case "append_to_note":
            let text = try arguments.required("text")
            let section = arguments.string("section")
            if arguments.string("position")?.lowercased() == "top" {
                return { NoteSectionPolicy.prepend(text, toSection: section, in: $0) }
            }
            return { SectionAppendPolicy.append(text, toSection: section, in: $0) }
        case "set_plan_item":
            let item = try arguments.required("item")
            let done = arguments.bool("done") ?? true
            return { try PlanPolicy.setting(item, done: done, in: $0) }
        default:
            throw AgentError.notInBatch(tool)
        }
    }

    private func target(of arguments: MCPArguments) async throws -> VaultPath {
        if let task = arguments.string("task") {
            guard let found = try await useCases.findTask.execute(task) else { throw AgentError.noTask(task) }
            return found.path
        }
        return try await notePath(id: try arguments.required("id"))
    }

    private func rewrite(_ tool: String, _ arguments: MCPArguments) async throws -> NoteDocument {
        let change = try bodyChange(tool, arguments)
        let path = try await target(of: arguments)
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
