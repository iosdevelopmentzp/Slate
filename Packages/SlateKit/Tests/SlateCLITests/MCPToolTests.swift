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

    @Test func theCatalogHasTheTwentyFourTools() {
        #expect(MCPToolCatalog.tools.map(\.name) == [
            "list_folders", "list_notes", "search_notes", "read_note", "read_section", "list_backlinks", "create_note", "append_to_note",
            "replace_in_note", "update_section", "update_note", "batch_edit", "move_note", "trash_note", "attach_image", "open_in_slate",
            "project_context", "start_task", "set_task_status", "set_plan_item", "log_progress", "add_file", "list_files", "save_version",
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

    @Test func createNoteNeedsTheCreateFlag() async throws {
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

    @Test func createNoteMakesAMissingFolderWhereAgentsMayWrite() async throws {
        let answer = await call("create_note", ["folder": "notes/ABC-1/Details", "title": "Plan"])

        #expect(answer.isError == false, "\(answer.text)")
        #expect(try object(answer.text)["createdFolder"] as? String == "Notes/ABC-1/Details")
        #expect(FileManager.default.fileExists(atPath: vault.path("Notes/ABC-1/Details/Plan.md")))
    }

    @Test func createNoteDoesNotMakeAFolderWhereAgentsMayNotWrite() async throws {
        let answer = await call("create_note", ["folder": "Nowhere", "title": "Plan"])

        #expect(answer.isError)
        #expect(answer.text.hasPrefix("Agents may not change notes in Nowhere."))
        #expect(FileManager.default.fileExists(atPath: vault.path("Nowhere")) == false)
    }

    @Test func appendToNoteAtTheTopPutsTheNewestEntryFirst() async throws {
        let id = try await create("Changelog", body: "Intro\n\n## Changes\n\n- old\n")

        let answer = await call("append_to_note", ["id": .string(id), "text": "- new", "section": "Changes", "position": "top"])

        #expect(answer.isError == false, "\(answer.text)")
        #expect(try file("Notes/Changelog.md").hasSuffix("---\nIntro\n\n## Changes\n\n- new\n- old\n"))
    }

    @Test func readSectionGivesOneSectionAndTheHash() async throws {
        let id = try await create("Task", body: "## Status\n\nactive\n\n## Log\n\n- a\n")
        let hash = try object(await call("read_note", ["id": .string(id)]).text)["hash"] as? String

        let section = try object(await call("read_section", ["id": .string(id), "heading": "status"]).text)
        let missing = await call("read_section", ["id": .string(id), "heading": "Plan"])

        #expect(section["text"] as? String == "active")
        #expect(section["hash"] as? String == hash)
        #expect(missing.isError)
        #expect(missing.text == "The note has no section Plan. Sections: ## Status, ## Log.")
    }

    @Test func updateSectionChangesOnlyThatSection() async throws {
        let id = try await create("Task", body: "## Status\n\nactive\n\n## Log\n\n- a\n")
        let hash = try #require(try object(await call("read_section", ["id": .string(id), "heading": "Status"]).text)["hash"] as? String)

        let answer = await call("update_section", ["id": .string(id), "heading": "Status", "text": "review", "expectedHash": .string(hash)])
        let stale = await call("update_section", ["id": .string(id), "heading": "Status", "text": "done", "expectedHash": .string(hash)])

        #expect(answer.isError == false, "\(answer.text)")
        #expect(try file("Notes/Task.md").hasSuffix("---\n## Status\n\nreview\n\n## Log\n\n- a\n"))
        #expect(stale.text == "The note changed since you read it, read it again.")
        #expect(try await ports.agentChanges.changes(after: .distantPast).map(\.tool).last == "update_section")
    }

    @Test func replaceInNoteChangesOneLine() async throws {
        let id = try await create("Plan", body: "- [ ] code\n- [ ] tests\n")

        let answer = await call("replace_in_note", ["id": .string(id), "old": "- [ ] tests", "new": "- [x] tests"])
        let twice = await call("replace_in_note", ["id": .string(id), "old": "- [", "new": "* ["])
        let missing = await call("replace_in_note", ["id": .string(id), "old": "- [ ] docs", "new": "x"])

        #expect(answer.isError == false, "\(answer.text)")
        #expect(try file("Notes/Plan.md").hasSuffix("---\n- [ ] code\n- [x] tests\n"))
        #expect(twice.text == "The note has this text 2 times. Add more of the text around it, so that it matches one place.")
        #expect(missing.isError)
    }

    @Test func replaceInANoteInAForbiddenFolderIsRefused() async throws {
        try await allow(AgentPermissions(writableFolders: ["Work"]))
        let id = try await create("Plan", in: "Work", body: "a")
        try await allow(AgentPermissions(writableFolders: ["Notes"]))

        let answer = await call("replace_in_note", ["id": .string(id), "old": "a", "new": "b"])

        #expect(answer.isError)
        #expect(try file("Work/Plan.md").hasSuffix("---\na\n"))
    }

    @Test func batchEditChangesSeveralNotesAndKeepsOneVersion() async throws {
        let plan = try await create("Plan", body: "## Status\n\nactive\n\n## Steps\n\n- [ ] a\n- [ ] b\n")
        let log = try await create("Changelog", body: "## Changes\n\n- old\n")
        let operations: Value = [
            ["tool": "replace_in_note", "id": .string(plan), "old": "- [ ] a", "new": "- [x] a"],
            ["tool": "update_section", "id": .string(plan), "heading": "Status", "text": "review"],
            ["tool": "append_to_note", "id": .string(log), "section": "Changes", "text": "- new", "position": "top"],
        ]

        let answer = await call("batch_edit", ["operations": operations])

        #expect(answer.isError == false, "\(answer.text)")
        #expect(try object(answer.text)["operations"] as? Int == 3)
        #expect(try file("Notes/Plan.md").hasSuffix("---\n## Status\n\nreview\n\n## Steps\n\n- [x] a\n- [ ] b\n"))
        #expect(try file("Notes/Changelog.md").hasSuffix("## Changes\n\n- new\n- old\n"))
        #expect(try await ports.agentChanges.changes(after: .distantPast).map(\.tool).suffix(2) == ["batch_edit", "batch_edit"])
    }

    @Test func batchEditWritesNothingWhenOneOperationFails() async throws {
        let plan = try await create("Plan", body: "- [ ] a\n")
        let before = try file("Notes/Plan.md")
        let operations: Value = [
            ["tool": "replace_in_note", "id": .string(plan), "old": "- [ ] a", "new": "- [x] a"],
            ["tool": "replace_in_note", "id": .string(plan), "old": "- [ ] z", "new": "x"],
        ]

        let answer = await call("batch_edit", ["operations": operations])
        let wrongTool = await call("batch_edit", ["operations": [["tool": "trash_note", "id": .string(plan)]]])

        #expect(answer.isError)
        #expect(answer.text.hasPrefix("Operation 2: The note does not have this text."))
        #expect(answer.text.hasSuffix("Nothing was written."))
        #expect(try file("Notes/Plan.md") == before)
        #expect(wrongTool.text.hasPrefix("Operation 1: batch_edit takes replace_in_note"))
    }

    @Test func batchEditTakesTheOperationsAsAJSONString() async throws {
        let plan = try await create("Plan", body: "- [ ] a\n")

        let answer = await call("batch_edit", ["operations": .string("[{\"tool\": \"replace_in_note\", \"id\": \"\(plan)\", \"old\": \"[ ]\", \"new\": \"[x]\"}]")])

        #expect(answer.isError == false, "\(answer.text)")
        #expect(try file("Notes/Plan.md").hasSuffix("---\n- [x] a\n"))
    }

    @Test func listNotesGivesHeadingsWhenAsked() async throws {
        try await create("Details A", body: "Same start\n\n## Login\n")
        try await create("Details B", body: "Same start\n\n## Payments\n")

        let plain = try array(await call("list_notes").text)
        let detailed = try array(await call("list_notes", ["headings": true]).text)

        #expect(plain.allSatisfy { $0["headings"] == nil })
        #expect(detailed.compactMap { $0["headings"] as? [String] } == [["## Payments"], ["## Login"]])
    }

    @Test func listBacklinksFindsTheNotesThatLinkHere() async throws {
        let id = try await create("Changelog", body: "text")
        try await create("Release", body: "See [[Changelog]].")
        try await create("Other", body: "nothing")

        let links = try array(await call("list_backlinks", ["id": .string(id)]).text)

        #expect(links.map { $0["title"] as? String } == ["Release"])
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
        #expect(try object(answer.text)["placedAt"] as? String == "the end of the note")
    }

    @Test func attachImageUnderASection() async throws {
        let id = try await create("Bug", body: "## Screens\n\n## Log\n\n- a\n")

        let answer = await call("attach_image", ["id": .string(id), "base64": .string(Self.png.base64EncodedString()), "section": "Screens"])

        #expect(try object(answer.text)["placedAt"] as? String == "the end of the section Screens")
        #expect(try file("Notes/Bug.md").contains("## Screens\n\n![](../_attachments/"))
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
        #expect(await call("append_to_note", ["id": "x"]).text == "Missing: text. append_to_note takes id, text, position, section; required: id, text. Nothing was changed. Call it again with these names.")
        #expect(await call("append_to_note", ["id": "x", "text": "y"]).text.hasPrefix("No note has the id x."))
        #expect(await call("delete_everything").text.hasPrefix("Slate has no tool delete_everything."))
    }

    @Test func createNoteRefusesAnUnknownArgumentAndWritesNothing() async throws {
        let answer = await call("create_note", ["folder": "Notes", "title": "Analysis", "text": "The whole analysis"])

        #expect(answer.isError)
        #expect(answer.text.hasPrefix("create_note has no argument text. create_note takes folder, title, body; required: folder, title."))
        #expect(FileManager.default.fileExists(atPath: vault.url.appendingPathComponent("Notes/Analysis.md").path) == false)
    }

    @Test func createNoteSaysHowManyLinesItWroteAndWarnsAboutAnEmptyNote() async throws {
        let full = try object(await call("create_note", ["folder": "Notes", "title": "Plan", "body": "One\nTwo\n"]).text)
        let empty = try object(await call("create_note", ["folder": "Notes", "title": "Empty"]).text)

        #expect(full["lines"] as? Int == 2)
        #expect(full["warning"] == nil)
        #expect(empty["lines"] as? Int == 0)
        #expect(empty["warning"] as? String == "The note has no text. Add it with update_note and the argument body.")
    }

    @Test func updateNoteNamesEveryMissingArgumentAtOnce() async throws {
        let id = try await create("Groceries", body: "Milk")

        let answer = await call("update_note", ["id": .string(id), "text": "Bread"])
        let written = await call("update_note", ["id": .string(id), "body": "Bread\nEggs", "expectedHash": .string(try object(await call("read_note", ["id": .string(id)]).text)["hash"] as? String ?? "")])

        #expect(answer.text.hasPrefix("update_note has no argument text. Missing: body, expectedHash."))
        #expect(try object(written.text)["lines"] as? Int == 2)
    }

    @Test func aValueOfTheWrongTypeIsRefused() async throws {
        let answer = await call("list_notes", ["limit": "many", "headings": "yes"])

        #expect(answer.isError)
        #expect(answer.text.hasPrefix("Wrong type: headings (true or false), limit (a number)."))
    }

    @Test func batchEditRefusesAnUnknownArgumentInAnOperation() async throws {
        let log = try await create("Changelog", body: "## Changes\n\n- old\n")
        let before = try file("Notes/Changelog.md")

        let answer = await call("batch_edit", ["operations": [["tool": "append_to_note", "id": .string(log), "heading": "Changes", "text": "- new"]]])

        #expect(answer.text.hasPrefix("Operation 1: append_to_note has no argument heading."))
        #expect(try file("Notes/Changelog.md") == before)
    }

    @Test func everyToolRefusesUnknownArgumentsInItsSchema() {
        for tool in MCPToolCatalog.tools {
            let schema = tool.inputSchema.objectValue ?? [:]
            let properties = Set((schema["properties"]?.objectValue ?? [:]).keys)
            let required = (schema["required"]?.arrayValue ?? []).compactMap(\.stringValue)
            #expect(schema["additionalProperties"] == false, "\(tool.name)")
            #expect(required.allSatisfy(properties.contains), "\(tool.name)")
        }
    }

    @Test func anOldServerRefusesEveryCallAfterAnInstall() async throws {
        let tool = vault.url.appendingPathComponent(".slate/slate")
        try Data("old".utf8).write(to: tool)
        var old = runner
        old.executable = ExecutableStamp(path: tool.path)
        try Data("new".utf8).write(to: vault.url.appendingPathComponent(".slate/slate.new"))
        _ = try FileManager.default.replaceItemAt(tool, withItemAt: vault.url.appendingPathComponent(".slate/slate.new"))

        let answer = await old.call("create_note", arguments: ["folder": "Notes", "title": "Plan", "body": "One"])

        #expect(answer.isError == true)
        #expect(FileManager.default.fileExists(atPath: vault.url.appendingPathComponent("Notes/Plan.md").path) == false)
        #expect(await call("list_folders").isError == false)
    }
}
