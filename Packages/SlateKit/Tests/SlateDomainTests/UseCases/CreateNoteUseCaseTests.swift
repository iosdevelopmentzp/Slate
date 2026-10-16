import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct CreateNoteUseCaseTests {
    private let ports: Ports
    private let spies: PortSpies

    init() {
        (ports, spies) = Ports.spies()
    }

    @Test func taskGoesToTasksFromItsTemplate() async throws {
        let created = try await UseCases(ports: ports).create.execute(NoteDraft(title: "ABC-1 Fix it", type: "task"))

        let path = VaultPath(rawValue: "Tasks/ABC-1 Fix it.md")
        #expect(created.document.path == path)
        #expect(created.document.header.type == "task")
        #expect(created.document.header.status == "todo")
        #expect(created.document.header.created == spies.clock.current)
        #expect(created.document.body.hasPrefix("## Context\n\n"))
        #expect(created.caret == "## Context\n\n".utf16.count)
        #expect(spies.files.calls == [.create(path)])
        #expect(spies.index.calls == [.upsert(path)])
        let text = try #require(spies.files.text(at: path))
        #expect(text.hasPrefix("---\nid: "))
        #expect(text.contains("title: ABC-1 Fix it\ntype: task\ncreated: 2027-01-15T11:00:00+03:00"))
    }

    @Test func noteWithoutTitleIsUntitledInTheRequestedSpace() async throws {
        let created = try await UseCases(ports: ports).create.execute(NoteDraft(space: SpaceName(rawValue: "Notes")))

        #expect(created.document.path == VaultPath(rawValue: "Notes/Untitled.md"))
        #expect(created.document.title == "Untitled")
        #expect(created.document.body.isEmpty)
        #expect(created.caret == 0)
    }

    @Test func spaceDefaultTypeApplies() async throws {
        let created = try await UseCases(ports: ports).create.execute(NoteDraft(space: SpaceName(rawValue: "Tasks")))

        #expect(created.document.header.type == "task")
    }

    @Test func stemIsUniqueInTheFolder() async throws {
        spies.files.seed(VaultPath(rawValue: "Inbox/Untitled.md"), "x")
        spies.files.seed(VaultPath(rawValue: "Inbox/untitled 2.md"), "x")

        let created = try await UseCases(ports: ports).create.execute(NoteDraft())

        #expect(created.document.path == VaultPath(rawValue: "Inbox/Untitled 3.md"))
    }

    @Test func titleIsKeptAsTypedWhileTheStemIsSanitised() async throws {
        let created = try await UseCases(ports: ports).create.execute(NoteDraft(title: "a/b: c?"))

        #expect(created.document.path == VaultPath(rawValue: "Inbox/a-b- c.md"))
        #expect(created.document.title == "a/b: c?")
    }

    @Test func userTemplateIsUsed() async throws {
        spies.templates.bodies["note"] = "# {{title}}\n{{cursor}}"

        let created = try await UseCases(ports: ports).create.execute(NoteDraft(title: "Hi"))

        #expect(created.document.body == "# Hi\n")
        #expect(created.caret == 5)
    }
}
