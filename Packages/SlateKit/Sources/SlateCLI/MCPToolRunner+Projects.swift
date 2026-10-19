import Foundation
import SlateDomain

extension MCPToolRunner {
    static let maxFileSize = 200 * 1024 * 1024

    func projectContext(_ arguments: MCPArguments) async throws -> String {
        let match = try await project(arguments, directory: directory(arguments))
        let tasks = try await useCases.projectTasks.execute(in: match.space.folder)
        let current = tasks.first { $0.matches(branch: match.repository?.branch) }
        let notes = try await ports.index.summaries(space: match.space.folder).filter { $0.path.depth == 1 }
        var object: [String: Any] = [
            "project": match.space.folder.rawValue,
            "folder": match.space.folder.rawValue,
            "absolutePath": root.appendingPathComponent(match.space.folder.rawValue, isDirectory: true).path,
            "tasks": tasks.map(taskObject),
            "notes": notes.map { ["id": $0.id.rawValue, "title": $0.title, "path": $0.path.rawValue] },
            "rules": Self.projectRules,
        ]
        if let repository = match.repository {
            var info: [String: Any] = ["root": repository.root, "mainRoot": repository.mainRoot]
            info["branch"] = repository.branch
            info["remote"] = repository.remote
            object["repository"] = info
        }
        object["currentTask"] = current.map(taskObject)
        return json(object)
    }

    func startTask(_ arguments: MCPArguments) async throws -> String {
        let match = try await project(arguments, directory: directory(arguments))
        let title = try arguments.required("title")
        try await permissions().checkCreate(in: FolderPath(space: match.space.folder))
        let branch = arguments.string("branch") ?? match.repository?.branch
        let created = try await useCases.startTask.execute(in: match.space.folder, title: title, ticket: arguments.string("ticket"), branch: branch)
        let document = created.document
        await afterWrite("start_task", title: document.title, path: document.path)
        return json([
            "id": document.id.rawValue,
            "title": document.title,
            "path": document.path.rawValue,
            "folder": document.path.folder,
            "absoluteFolder": root.appendingPathComponent(document.path.folder, isDirectory: true).path,
            "hash": document.hash.rawValue,
        ])
    }

    func setTaskStatus(_ arguments: MCPArguments) async throws -> String {
        let task = try await findTask(try arguments.required("task"))
        let raw = try arguments.required("status").lowercased()
        guard let status = NoteStatus(rawValue: raw) else { throw AgentError.missingArgument("status: one of \(NoteStatus.allCases.map(\.rawValue).joined(separator: ", "))") }
        try await permissions().checkWrite(task.path)
        await beforeWrite()
        try await useCases.setTaskStatus.execute(task.path, status: status)
        await afterWrite("set_task_status", title: task.title, path: task.path)
        return "\(task.title) is \(status.rawValue) now."
    }

    func logProgress(_ arguments: MCPArguments) async throws -> String {
        let task = try await findTask(try arguments.required("task"))
        let text = try arguments.required("text")
        try await permissions().checkWrite(task.path)
        await beforeWrite()
        let logged = try await useCases.logProgress.execute(text, to: task.path)
        let document = logged.document
        await afterWrite("log_progress", title: document.title, path: document.path)
        return json(["id": document.id.rawValue, "path": document.path.rawValue, "entry": logged.entry, "hash": document.hash.rawValue])
    }

    func addFile(_ arguments: MCPArguments) async throws -> String {
        let folder = try await existingFolder(try arguments.required("folder"))
        let permissions = try await permissions()
        guard permissions.canWrite(in: folder) else { throw AgentError.folderNotAllowed(folder.rawValue, allowed: permissions.writableFolders) }
        let source = try fileSource(arguments)
        defer { if source.isTemporary { try? FileManager.default.removeItem(at: source.url.deletingLastPathComponent()) } }
        let path = try await ports.files.importFile(source.url, into: folder)
        await afterWrite("add_file", title: path.fileName, path: path)
        return json(["path": path.rawValue, "absolutePath": root.appendingPathComponent(path.rawValue).path])
    }

    func listFiles(_ arguments: MCPArguments) async throws -> String {
        let folder = try await existingFolder(try arguments.required("folder"))
        let files = try await ports.files.files(in: folder)
        return json(files.map { meta in
            [
                "name": meta.path.fileName,
                "path": meta.path.rawValue,
                "absolutePath": root.appendingPathComponent(meta.path.rawValue).path,
                "size": meta.size,
                "modified": ISO8601DateFormatter().string(from: meta.modified),
            ] as [String: Any]
        })
    }

    func saveVersion(_ arguments: MCPArguments) async throws -> String {
        let name = try arguments.required("name").replacingOccurrences(of: "\n", with: " ")
        let outcome = try await useCases.snapshot.execute(push: false, message: "version: \(name)")
        return outcome.committed ? "Saved the version \(name)." : "Nothing changed since the last version, or versions are off in Slate's settings."
    }

    private func directory(_ arguments: MCPArguments) -> URL {
        arguments.string("path").map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath, isDirectory: true) } ?? workingDirectory
    }

    var workingDirectory: URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    }

    private func project(_ arguments: MCPArguments, directory: URL) async throws -> ProjectMatch {
        let known = try await ports.config.spaces().spaces.filter(\.isProject).map(\.folder.rawValue)
        if let name = arguments.string("project") {
            guard let space = try await useCases.findProject.execute(named: name) else { throw AgentError.noProject(name, known: known) }
            return ProjectMatch(space: space, repository: await ports.repositories.inspect(directory))
        }
        guard let match = try await useCases.findProject.execute(directory: directory) else { throw AgentError.noProject(directory.path, known: known) }
        return match
    }

    private func findTask(_ raw: String) async throws -> ProjectTask {
        guard let found = try await useCases.findTask.execute(raw) else { throw AgentError.noTask(raw) }
        return found
    }

    private func fileSource(_ arguments: MCPArguments) throws -> (url: URL, isTemporary: Bool) {
        if let data = arguments.data("base64") {
            guard data.count <= Self.maxFileSize else { throw AgentError.fileTooLarge }
            let name = FileNamePolicy.cleaned(try arguments.required("name")) ?? "file"
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("slate-\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent(name)
            try data.write(to: url)
            return (url, true)
        }
        guard let raw = arguments.string("path") else { throw AgentError.missingArgument("path or base64 with name") }
        let url = URL(fileURLWithPath: (raw as NSString).expandingTildeInPath)
        let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        guard values?.isRegularFile == true else { throw AgentError.notAFile(raw) }
        guard (values?.fileSize ?? 0) <= Self.maxFileSize else { throw AgentError.fileTooLarge }
        guard let name = arguments.string("name").flatMap(FileNamePolicy.cleaned), name != url.lastPathComponent else { return (url, false) }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("slate-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let renamed = folder.appendingPathComponent(name)
        try FileManager.default.copyItem(at: url, to: renamed)
        return (renamed, true)
    }

    private func taskObject(_ task: ProjectTask) -> [String: Any] {
        var object: [String: Any] = [
            "id": task.id.rawValue,
            "title": task.title,
            "status": task.status.rawValue,
            "path": task.path.rawValue,
            "folder": task.path.folder,
            "absoluteFolder": root.appendingPathComponent(task.path.folder, isDirectory: true).path,
            "updated": ISO8601DateFormatter().string(from: task.updated),
        ]
        object["ticket"] = task.ticket
        object["branch"] = task.branch
        return object
    }

    static let projectRules = """
    Keep the documentation of a task in its task folder. The task note holds Context, Plan, Findings, Links, Questions and Log. \
    Put longer findings or decisions in more notes in the same folder (create_note with that folder). Add logs, screenshots and other files with add_file. \
    At the end of each session call log_progress with what was done, what is left and the next step, so the next session can go on. \
    Set the status with set_task_status: todo, active, review, done or dropped.
    """
}
