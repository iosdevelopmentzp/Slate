import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct ExtensionUseCaseTests {
    private let ports: Ports
    private let spies: PortSpies

    init() {
        (ports, spies) = Ports.spies()
    }

    @Test func toggleTodoChecksTheLineInTheFile() async throws {
        let path = VaultPath(rawValue: "Notes/A.md")
        spies.files.seed(path, NoteText.make(id: "a", title: "A", body: "x\n- [ ] first\n- [ ] second"))
        _ = try await UseCases(ports: ports).reindex.execute(.all)

        let document = try await UseCases(ports: ports).toggleTodo.execute(TodoItem(noteID: NoteID(rawValue: "a"), line: 2, text: "second", isDone: false))

        #expect(document?.body == "x\n- [ ] first\n- [x] second")
    }

    @Test func toggleTodoRefusesAChangedLine() async throws {
        let path = VaultPath(rawValue: "Notes/A.md")
        spies.files.seed(path, NoteText.make(id: "a", title: "A", body: "- [ ] other"))
        _ = try await UseCases(ports: ports).reindex.execute(.all)

        let document = try await UseCases(ports: ports).toggleTodo.execute(TodoItem(noteID: NoteID(rawValue: "a"), line: 0, text: "first", isDone: false))

        #expect(document == nil)
    }

    @Test func actionGetsTheNoteEnvironmentAndCanAppend() async throws {
        let path = VaultPath(rawValue: "Tasks/ABC-1.md")
        spies.files.seed(path, NoteText.make(id: "t", title: "ABC-1", type: "task", body: "Body"))
        let document = try NoteCodec.decode(try await spies.files.read(path))
        spies.actions.result = ActionResult(output: "line one\nline two", exitCode: 0)
        let action = ActionDefinition(id: "x", title: "X", command: "echo", output: .appendToNote)

        let result = try await UseCases(ports: ports).runAction.execute(action, on: document, vault: URL(fileURLWithPath: "/vault"))

        #expect(spies.actions.calls.first?.environment["SLATE_NOTE_PATH"] == "/vault/Tasks/ABC-1.md")
        #expect(spies.actions.calls.first?.environment["SLATE_NOTE_TITLE"] == "ABC-1")
        #expect(result.appended?.body == "Body\n\n```log\nline one\nline two\n```\n")
    }

    @Test func actionConditions() {
        let path = VaultPath(rawValue: "Tasks/A.md")
        let task = NoteDocument(path: path, header: NoteHeader(type: "task", branch: "feature/x"), body: "", hash: ContentHash(rawValue: ""), meta: FileMeta(path: path, created: .now, modified: .now, size: 0))

        #expect(ActionDefinition(id: "a", title: "a", command: "", condition: .hasBranch).applies(to: task))
        #expect(ActionDefinition(id: "a", title: "a", command: "", condition: .hasMR).applies(to: task) == false)
        #expect(ActionDefinition(id: "a", title: "a", command: "", condition: .task).applies(to: task))
    }
}
