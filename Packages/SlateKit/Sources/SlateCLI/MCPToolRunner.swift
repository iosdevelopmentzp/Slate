import Foundation
import MCP
import SlateDomain

struct MCPToolRunner: Sendable {
    static let notePrefix = "slate://note/"

    let root: URL
    let ports: Ports
    let useCases: UseCases
    let open: @Sendable (URL) async throws -> Void

    func call(_ name: String, arguments: [String: Value]?) async -> CallTool.Result {
        do {
            _ = try await useCases.reindex.execute(.all)
            let answer = try await run(name, MCPArguments(arguments))
            return CallTool.Result(content: [.text(text: answer, annotations: nil, _meta: nil)])
        } catch {
            return CallTool.Result(content: [.text(text: error.localizedDescription, annotations: nil, _meta: nil)], isError: true)
        }
    }

    private func run(_ name: String, _ arguments: MCPArguments) async throws -> String {
        switch name {
        case "list_folders": try await listFolders()
        case "list_notes": try await listNotes(arguments)
        case "search_notes": try await searchNotes(arguments)
        case "read_note": try await readNote(arguments)
        case "create_note": try await createNote(arguments)
        case "append_to_note": try await appendToNote(arguments)
        case "update_note": try await updateNote(arguments)
        case "move_note": try await moveNote(arguments)
        case "trash_note": try await trashNote(arguments)
        case "attach_image": try await attachImage(arguments)
        case "open_in_slate": try await openInSlate(arguments)
        case "project_context": try await projectContext(arguments)
        case "start_task": try await startTask(arguments)
        case "set_task_status": try await setTaskStatus(arguments)
        case "log_progress": try await logProgress(arguments)
        case "add_file": try await addFile(arguments)
        case "list_files": try await listFiles(arguments)
        case "save_version": try await saveVersion(arguments)
        default: throw AgentError.unknownTool(name)
        }
    }

    func resources() async throws -> [Resource] {
        _ = try await useCases.reindex.execute(.all)
        let summaries = try await ports.index.summaries(space: nil).sorted { $0.updated > $1.updated }
        return summaries.prefix(50).map { summary in
            Resource(name: summary.title, uri: Self.uri(for: summary.id), description: summary.path.rawValue, mimeType: "text/markdown")
        }
    }

    func readResource(_ uri: String) async throws -> String {
        guard uri.hasPrefix(Self.notePrefix), let id = String(uri.dropFirst(Self.notePrefix.count)).removingPercentEncoding else {
            throw AgentError.noteNotFound(uri)
        }
        _ = try await useCases.reindex.execute(.all)
        let path = try await notePath(id: id)
        return String(decoding: try await ports.files.read(path).data, as: UTF8.self)
    }

    static func uri(for id: NoteID) -> String {
        notePrefix + (id.rawValue.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))) ?? id.rawValue)
    }

    func permissions() async throws -> AgentPermissions {
        try await ports.config.agentPermissions()
    }

    func notePath(id: String) async throws -> VaultPath {
        guard let summary = try await ports.index.summary(id: NoteID(rawValue: id)) else { throw AgentError.noteNotFound(id) }
        return summary.path
    }

    func notePath(_ arguments: MCPArguments) async throws -> VaultPath {
        if let id = arguments.string("id") {
            return try await notePath(id: id)
        }
        if let path = arguments.string("path") {
            return try AgentPathPolicy.notePath(from: path, root: root)
        }
        throw AgentError.missingArgument("id or path")
    }

    func folders() async throws -> [FolderPath] {
        let spaces = try await ports.config.spaces().spaces.map { FolderPath(space: $0.folder) }
        return (spaces + (try await ports.files.folders())).sorted { $0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending }
    }

    func existingFolder(_ raw: String) async throws -> FolderPath {
        let folder = try AgentPathPolicy.folder(from: raw)
        guard let found = try await folders().first(where: { StemPolicy.isSame($0.rawValue, folder.rawValue) }) else {
            throw AgentError.noFolder(raw)
        }
        return found
    }

    func document(at path: VaultPath) async throws -> NoteDocument {
        try NoteCodec.decode(try await ports.files.read(path))
    }

    func beforeWrite() async {
        _ = try? await useCases.snapshot.execute(push: false)
    }

    func afterWrite(_ tool: String, title: String, path: VaultPath) async {
        try? await ports.agentChanges.record(AgentChange(date: ports.clock.now(), tool: tool, title: title, path: path))
        _ = try? await useCases.snapshot.execute(push: false, message: "agent: \(tool) \(title)")
    }

    func json(_ object: Any) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }

    func summaryObject(_ summary: NoteSummary) -> [String: Any] {
        [
            "id": summary.id.rawValue,
            "title": summary.title,
            "folder": summary.path.folder,
            "path": summary.path.rawValue,
            "updated": ISO8601DateFormatter().string(from: summary.updated),
            "pinned": summary.pinned,
            "preview": summary.preview,
        ]
    }
}
