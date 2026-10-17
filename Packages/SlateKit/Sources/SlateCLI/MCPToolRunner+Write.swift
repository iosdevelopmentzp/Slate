import Foundation
import SlateDomain

extension MCPToolRunner {
    func createNote(_ arguments: MCPArguments) async throws -> String {
        let folder = try await existingFolder(try arguments.required("folder"))
        let title = try arguments.required("title")
        try await permissions().checkCreate(in: folder)
        let body = arguments.raw("body").map { $0.hasSuffix("\n") || $0.isEmpty ? $0 : $0 + "\n" }
        let created = try await useCases.create.execute(NoteDraft(title: title, body: body ?? "", folder: folder))
        let document = created.document
        await afterWrite("create_note", title: document.title, path: document.path)
        return json(["id": document.id.rawValue, "title": document.title, "path": document.path.rawValue, "hash": document.hash.rawValue])
    }

    func appendToNote(_ arguments: MCPArguments) async throws -> String {
        let id = try arguments.required("id")
        let text = try arguments.required("text")
        let path = try await notePath(id: id)
        try await permissions().checkWrite(path)
        await beforeWrite()
        let document = try await useCases.append.execute(text, to: .path(path), section: arguments.string("section"))
        await afterWrite("append_to_note", title: document.title, path: document.path)
        return json(["id": document.id.rawValue, "path": document.path.rawValue, "hash": document.hash.rawValue])
    }

    func updateNote(_ arguments: MCPArguments) async throws -> String {
        let id = try arguments.required("id")
        guard let body = arguments.raw("body") else { throw AgentError.missingArgument("body") }
        let expected = try arguments.required("expectedHash")
        let path = try await notePath(id: id)
        try await permissions().checkWrite(path)
        let current = try await document(at: path)
        guard current.hash.rawValue == expected else { throw AgentError.staleNote }
        await beforeWrite()
        let result = try await useCases.save.execute(current, header: current.header, body: Self.bodyWithoutHeader(body))
        guard let saved = result.document else { throw AgentError.staleNote }
        await afterWrite("update_note", title: saved.title, path: saved.path)
        return json(["id": saved.id.rawValue, "path": saved.path.rawValue, "hash": saved.hash.rawValue])
    }

    func moveNote(_ arguments: MCPArguments) async throws -> String {
        let id = try arguments.required("id")
        let folderName = try arguments.required("folder")
        let path = try await notePath(id: id)
        let folder = try await existingFolder(folderName)
        let permissions = try await permissions()
        try permissions.checkWrite(path)
        guard permissions.canWrite(in: folder) else { throw AgentError.folderNotAllowed(folder.rawValue, allowed: permissions.writableFolders) }
        await beforeWrite()
        let target = try await useCases.move.execute(path, toFolder: folder)
        let document = try await document(at: target)
        await afterWrite("move_note", title: document.title, path: target)
        return json(["id": document.id.rawValue, "path": target.rawValue, "hash": document.hash.rawValue])
    }

    func trashNote(_ arguments: MCPArguments) async throws -> String {
        let path = try await notePath(id: try arguments.required("id"))
        try await permissions().checkTrash(path)
        let title = try await document(at: path).title
        await beforeWrite()
        _ = try await useCases.trash.execute(path)
        await afterWrite("trash_note", title: title, path: path)
        return "Moved \(title) to the Trash. The owner can restore it in Slate for 30 days."
    }

    func attachImage(_ arguments: MCPArguments) async throws -> String {
        let path = try await notePath(id: try arguments.required("id"))
        try await permissions().checkWrite(path)
        let data = try await imageData(arguments)
        guard data.count <= AttachmentPolicy.maxImportSize else { throw AgentError.imageTooLarge }
        guard let fileExtension = ImageTypePolicy.fileExtension(of: data) else { throw AgentError.notAnImage }
        await beforeWrite()
        let markdown = try await useCases.importAttachment.execute(data: data, fileExtension: fileExtension, source: "agent", for: path)
        let caption = (arguments.string("caption") ?? "").replacingOccurrences(of: "]", with: ")").replacingOccurrences(of: "\n", with: " ")
        let block = caption.isEmpty ? markdown : markdown.replacingOccurrences(of: "![](", with: "![\(caption)](")
        let document = try await useCases.append.execute(block, to: .path(path), section: nil)
        await afterWrite("attach_image", title: document.title, path: document.path)
        return json(["id": document.id.rawValue, "path": document.path.rawValue, "image": block, "hash": document.hash.rawValue])
    }

    private func imageData(_ arguments: MCPArguments) async throws -> Data {
        if let data = arguments.data("base64") {
            return data
        }
        guard let raw = arguments.string("path") else { throw AgentError.missingArgument("base64 or path") }
        let url = URL(fileURLWithPath: (raw as NSString).expandingTildeInPath)
        guard let size = await ports.attachments.externalSize(url) else { throw AgentError.notAnImage }
        guard size <= AttachmentPolicy.maxImportSize else { throw AgentError.imageTooLarge }
        return try Data(contentsOf: url)
    }

    static func bodyWithoutHeader(_ text: String) -> String {
        guard text.hasPrefix("---\n"), let end = text.range(of: "\n---\n", range: text.index(text.startIndex, offsetBy: 4)..<text.endIndex) else { return text }
        return String(text[end.upperBound...])
    }
}
