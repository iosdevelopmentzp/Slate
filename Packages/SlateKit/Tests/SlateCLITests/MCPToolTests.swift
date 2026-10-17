import Foundation
import MCP
import SlateData
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateCLI

@Suite(.serialized) struct MCPToolTests {
    private let vault: TemporaryDirectory
    private let support: TemporaryDirectory
    private let keyValues = SpyKeyValueStore()
    private let opened = OpenedURLs()
    private let ports: Ports
    private let runner: MCPToolRunner

    static let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A] + [UInt8](repeating: 1, count: 24))

    init() throws {
        vault = try TemporaryDirectory()
        support = try TemporaryDirectory()
        for folder in ["Notes", "Work/Clients", ".slate", "_attachments"] {
            try FileManager.default.createDirectory(at: vault.url.appendingPathComponent(folder), withIntermediateDirectories: true)
        }
        HistorySettings(isEnabled: false).save(to: keyValues)
        ports = try Ports.live(root: vault.url, support: support.url, keyValues: keyValues, recorder: NoopRecorder())
        let opened = opened
        runner = MCPToolRunner(root: vault.url, ports: ports, useCases: UseCases(ports: ports)) { url in opened.append(url) }
    }

    private func call(_ tool: String, _ arguments: [String: Value] = [:]) async -> (text: String, isError: Bool) {
        let result = await runner.call(tool, arguments: arguments)
        let text = result.content.compactMap { content -> String? in
            guard case .text(let text, _, _) = content else { return nil }
            return text
        }.joined()
        return (text, result.isError ?? false)
    }

    private func object(_ text: String) throws -> [String: Any] {
        try #require(try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any])
    }

    private func array(_ text: String) throws -> [[String: Any]] {
        try #require(try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [[String: Any]])
    }

    private func file(_ path: String) throws -> String {
        try String(contentsOf: vault.url.appendingPathComponent(path), encoding: .utf8)
    }

    private func allow(_ permissions: AgentPermissions) async throws {
        try await ports.config.saveAgentPermissions(permissions)
    }

    @discardableResult
    private func create(_ title: String, in folder: String = "Notes", body: String = "First line") async throws -> String {
        let answer = await call("create_note", ["folder": .string(folder), "title": .string(title), "body": .string(body)])
        #expect(answer.isError == false, "\(answer.text)")
        return try object(answer.text)["id"] as? String ?? ""
    }

    @Test func theCatalogHasTheElevenTools() {
        #expect(MCPToolCatalog.tools.map(\.name) == [
            "list_folders", "list_notes", "search_notes", "read_note", "create_note", "append_to_note",
            "update_note", "move_note", "trash_note", "attach_image", "open_in_slate",
        ])
        #expect(MCPToolCatalog.tools.allSatisfy { ($0.description ?? "").isEmpty == false })
    }

    @Test func listFoldersCountsNotesAndSaysWhereAgentsMayWrite() async throws {
        try await create("Groceries")

        let folders = try array(await call("list_folders").text)

        #expect(folders.map { $0["folder"] as? String } == ["Notes", "Work", "Work/Clients"])
        #expect(folders.map { $0["notes"] as? Int } == [1, 0, 0])
        #expect(folders.map { $0["writable"] as? Bool } == [true, false, false])
    }

    @Test func createNoteWritesAHeaderAndRecordsTheChange() async throws {
        let id = try await create("Groceries", body: "Milk")

        let text = try file("Notes/Groceries.md")
        #expect(text.contains("id: \(id)"))
        #expect(text.contains("title: Groceries"))
        #expect(text.hasSuffix("---\nMilk\n"))
        let changes = try await ports.agentChanges.changes(after: .distantPast)
        #expect(changes.map(\.tool) == ["create_note"])
        #expect(changes.map(\.title) == ["Groceries"])
    }

    @Test func createNoteInAForbiddenFolderIsRefusedAndWritesNothing() async throws {
        let answer = await call("create_note", ["folder": "Work", "title": "Plan"])

        #expect(answer.isError)
        #expect(answer.text.hasPrefix("Agents may not change notes in Work. Allowed: Notes."))
        #expect(FileManager.default.fileExists(atPath: vault.path("Work/Plan.md")) == false)
        #expect(try await ports.agentChanges.changes(after: .distantPast).isEmpty)
    }

    @Test func createNoteNeedsTheCreateFlagAndAFolderThatExists() async throws {
        #expect(await call("create_note", ["folder": "Nowhere", "title": "Plan"]).text == "There is no folder Nowhere. Use a name from list_folders.")
        try await allow(AgentPermissions(allowCreate: false))

        let answer = await call("create_note", ["folder": "Notes", "title": "Plan"])

        #expect(answer.isError)
        #expect(answer.text.hasPrefix("Agents may not create notes."))
    }

    @Test func createNoteInAnAllowedSubFolder() async throws {
        try await allow(AgentPermissions(writableFolders: ["Work"]))

        try await create("Call notes", in: "Work/Clients")

        #expect(FileManager.default.fileExists(atPath: vault.path("Work/Clients/Call notes.md")))
    }

    @Test func appendToNoteAddsUnderTheSection() async throws {
        let id = try await create("Groceries", body: "## To buy\n\n- Milk")

        let answer = await call("append_to_note", ["id": .string(id), "text": "- Eggs", "section": "To buy"])

        #expect(answer.isError == false, "\(answer.text)")
        #expect(try file("Notes/Groceries.md").hasSuffix("## To buy\n\n- Milk\n- Eggs\n"))
    }

    @Test func appendToANoteInAForbiddenFolderIsRefused() async throws {
        try await allow(AgentPermissions(writableFolders: ["Work"]))
        let id = try await create("Plan", in: "Work")
        try await allow(AgentPermissions(writableFolders: ["Notes"]))
        let before = try file("Work/Plan.md")

        let answer = await call("append_to_note", ["id": .string(id), "text": "more"])

        #expect(answer.isError)
        #expect(try file("Work/Plan.md") == before)
    }

    @Test func readNoteByIdOrPathReturnsTheFileAndItsHash() async throws {
        let id = try await create("Groceries", body: "Milk")

        let byID = try object(await call("read_note", ["id": .string(id)]).text)
        let byPath = try object(await call("read_note", ["path": "Notes/Groceries.md"]).text)

        #expect(byID["text"] as? String == (try file("Notes/Groceries.md")))
        #expect(byID["hash"] as? String == ContentHash.of(Data(try file("Notes/Groceries.md").utf8)).rawValue)
        #expect(byPath["id"] as? String == id)
    }

    @Test func readNoteRefusesPathsOutsideTheNotes() async throws {
        let answer = await call("read_note", ["path": "../outside.md"])
        let config = await call("read_note", ["path": ".slate/agents.json"])

        #expect(answer.isError)
        #expect(answer.text.contains("is not a note in the notes folder"))
        #expect(config.isError)
    }

    @Test func updateNoteReplacesTheBodyAndKeepsTheHeader() async throws {
        let id = try await create("Groceries", body: "Milk")
        let read = try object(await call("read_note", ["id": .string(id)]).text)

        let answer = await call("update_note", ["id": .string(id), "body": "Bread\n", "expectedHash": .string(read["hash"] as? String ?? "")])

        #expect(answer.isError == false, "\(answer.text)")
        let text = try file("Notes/Groceries.md")
        #expect(text.contains("id: \(id)"))
        #expect(text.hasSuffix("---\nBread\n"))
    }

    @Test func updateNoteWithTheWholeFileKeepsOneHeader() async throws {
        let id = try await create("Groceries", body: "Milk")
        let read = try object(await call("read_note", ["id": .string(id)]).text)
        let whole = (read["text"] as? String ?? "").replacingOccurrences(of: "Milk", with: "Bread")

        _ = await call("update_note", ["id": .string(id), "body": .string(whole), "expectedHash": .string(read["hash"] as? String ?? "")])

        let text = try file("Notes/Groceries.md")
        #expect(text.components(separatedBy: "id: ").count == 2)
        #expect(text.hasSuffix("---\nBread\n"))
    }

    @Test func updateNoteWithAStaleHashIsRefused() async throws {
        let id = try await create("Groceries", body: "Milk")
        let read = try object(await call("read_note", ["id": .string(id)]).text)
        _ = await call("append_to_note", ["id": .string(id), "text": "Eggs"])
        let before = try file("Notes/Groceries.md")

        let answer = await call("update_note", ["id": .string(id), "body": "Bread", "expectedHash": .string(read["hash"] as? String ?? "")])

        #expect(answer.isError)
        #expect(answer.text == "The note changed since you read it, read it again.")
        #expect(try file("Notes/Groceries.md") == before)
    }

    @Test func moveNoteNeedsBothFoldersAllowed() async throws {
        let id = try await create("Groceries")

        let refused = await call("move_note", ["id": .string(id), "folder": "Work"])
        try await allow(AgentPermissions(writableFolders: ["Notes", "Work"]))
        let moved = await call("move_note", ["id": .string(id), "folder": "Work/Clients"])

        #expect(refused.isError)
        #expect(moved.isError == false, "\(moved.text)")
        #expect(FileManager.default.fileExists(atPath: vault.path("Work/Clients/Groceries.md")))
        #expect(FileManager.default.fileExists(atPath: vault.path("Notes/Groceries.md")) == false)
    }

    @Test func trashNoteIsOffByDefault() async throws {
        let id = try await create("Groceries")

        let refused = await call("trash_note", ["id": .string(id)])
        try await allow(AgentPermissions(allowTrash: true))
        let trashed = await call("trash_note", ["id": .string(id)])

        #expect(refused.text.hasPrefix("Agents may not move notes to the Trash."))
        #expect(trashed.isError == false, "\(trashed.text)")
        #expect(FileManager.default.fileExists(atPath: vault.path("Notes/Groceries.md")) == false)
        #expect(try await ports.trash.items().map(\.originalPath.rawValue) == ["Notes/Groceries.md"])
    }

    @Test func attachImageCopiesTheImageAndAppendsTheBlock() async throws {
        let id = try await create("Groceries", body: "Milk")

        let answer = await call("attach_image", ["id": .string(id), "base64": .string(Self.png.base64EncodedString()), "caption": "The shelf"])

        #expect(answer.isError == false, "\(answer.text)")
        let names = try FileManager.default.contentsOfDirectory(atPath: vault.path("_attachments"))
        #expect(names.count == 1)
        #expect(names.first?.hasSuffix("-agent.png") == true)
        #expect(try Data(contentsOf: vault.url.appendingPathComponent("_attachments/\(names[0])")) == Self.png)
        #expect(try file("Notes/Groceries.md").hasSuffix("Milk\n\n![The shelf](../_attachments/\(names[0]))\n"))
    }

    @Test func attachImageFromAPathAndRefusesOtherFiles() async throws {
        let id = try await create("Groceries")
        let image = support.url.appendingPathComponent("photo.png")
        try Self.png.write(to: image)
        let text = try support.write("not an image at all", to: "notes.txt")

        let fromPath = await call("attach_image", ["id": .string(id), "path": .string(image.path)])
        let refused = await call("attach_image", ["id": .string(id), "path": .string(text.path)])

        #expect(fromPath.isError == false, "\(fromPath.text)")
        #expect(refused.text == "attach_image takes PNG, JPEG, GIF, HEIC or WebP images only.")
    }

    @Test func listAndSearchFindTheNotes() async throws {
        try await create("Groceries", body: "Milk and bread")
        try await allow(AgentPermissions(writableFolders: ["Notes", "Work"]))
        try await create("Client call", in: "Work/Clients", body: "Bread for the team")

        let all = try array(await call("list_notes").text)
        let work = try array(await call("list_notes", ["folder": "Work"]).text)
        let found = try array(await call("search_notes", ["query": "bread", "folder": "Notes"]).text)

        #expect(Set(all.compactMap { $0["title"] as? String }) == ["Groceries", "Client call"])
        #expect(work.compactMap { $0["path"] as? String } == ["Work/Clients/Client call.md"])
        #expect(found.compactMap { $0["title"] as? String } == ["Groceries"])
        #expect(found.first?["snippet"] != nil)
    }

    @Test func openInSlateUsesTheURLScheme() async throws {
        let id = try await create("Groceries")

        let answer = await call("open_in_slate", ["id": .string(id)])

        #expect(answer.text == "Slate shows Groceries.")
        #expect(opened.urls.map(\.absoluteString) == ["slate://open?id=\(id)"])
    }

    @Test func theNoteResourceGivesTheText() async throws {
        let id = try await create("Groceries", body: "Milk")

        let resources = try await runner.resources()
        let text = try await runner.readResource(MCPToolRunner.uri(for: NoteID(rawValue: id)))

        #expect(resources.map(\.uri) == ["slate://note/\(id)"])
        #expect(text == (try file("Notes/Groceries.md")))
    }

    @Test func missingArgumentsAndUnknownToolsAnswerWithASentence() async throws {
        #expect(await call("append_to_note", ["id": "x"]).text == "Pass text.")
        #expect(await call("append_to_note", ["id": "x", "text": "y"]).text.hasPrefix("No note has the id x."))
        #expect(await call("delete_everything").text.hasPrefix("Slate has no tool delete_everything."))
    }
}
