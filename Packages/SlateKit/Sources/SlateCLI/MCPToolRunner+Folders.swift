import Foundation
import SlateDomain

extension MCPToolRunner {

    func moveFolder(_ arguments: MCPArguments) async throws -> String {
        let folder = try await existingFolder(try arguments.required("folder"))
        let target = try AgentPathPolicy.folder(from: try arguments.required("to"))
        guard folder.parent != nil else { throw AgentError.badFolder(folder.rawValue) }
        let permissions = try await permissions()
        for checked in [folder, target] where permissions.canWrite(in: checked) == false {
            throw AgentError.folderNotAllowed(checked.rawValue, allowed: permissions.writableFolders)
        }
        guard let parent = target.parent else { throw AgentError.badFolder(target.rawValue) }
        await beforeWrite()
        var moved = folder
        if parent != folder.parent {
            let (into, exists) = try await resolvedFolder(parent.rawValue)
            if exists == false {
                try await ports.files.createFolder(into)
            }
            guard let done = try await useCases.moveFolder.execute(folder, into: into) else { throw AgentError.badFolder(target.rawValue) }
            moved = done.to
        }
        if moved.name != target.name {
            moved = try await useCases.renameFolder.execute(moved, to: target.name)
        }
        await afterWrite("move_folder", title: moved.name, path: VaultPath(rawValue: moved.rawValue))
        return json(["from": folder.rawValue, "folder": moved.rawValue])
    }

    func listTrash() async throws -> String {
        let items = try await ports.trash.items()
            .filter(\.originalPath.isNote)
            .sorted { $0.trashedAt > $1.trashedAt }
        let formatter = ISO8601DateFormatter()
        return json(items.map { ["path": $0.originalPath.rawValue, "title": $0.originalPath.stem, "trashed": formatter.string(from: $0.trashedAt)] })
    }

    func restoreNote(_ arguments: MCPArguments) async throws -> String {
        let wanted = try arguments.required("path").trimmingCharacters(in: .whitespacesAndNewlines)
        let items = try await ports.trash.items().filter(\.originalPath.isNote)
        let matching = items.filter { $0.originalPath.rawValue.caseInsensitiveCompare(wanted) == .orderedSame }
        guard let item = matching.max(by: { $0.trashedAt < $1.trashedAt }) else { throw AgentError.notInTrash(wanted) }
        try await permissions().checkWrite(item.originalPath)
        await beforeWrite()
        let document = try await useCases.restore.execute(item)
        await afterWrite("restore_note", title: document.title, path: document.path)
        return json(["id": document.id.rawValue, "title": document.title, "path": document.path.rawValue, "hash": document.hash.rawValue])
    }
}
