import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct StartTaskUseCaseTests {
    private let ports: Ports
    private let spies: PortSpies
    private let project = SpaceName(rawValue: "Notes")

    init() {
        (ports, spies) = Ports.spies()
        spies.config.config.spaces[2].project = ProjectInfo(id: "p1")
    }

    @Test func makesAFolderAndAnActiveTaskNoteFromTheTicketAndTitle() async throws {
        let created = try await UseCases(ports: ports).startTask.execute(in: project, title: "ABC-123 Fix login")

        let folder = FolderPath(rawValue: "Notes/ABC-123 Fix login")
        #expect(spies.files.folderNames.contains(folder))
        #expect(created.document.path == VaultPath(folder: folder, stem: "ABC-123 Fix login"))
        #expect(created.document.header.type == "task")
        #expect(created.document.header.status == "active")
        #expect(created.document.header.ticket == "ABC-123")
        #expect(created.document.header.branch == "feature/ABC-123-fix-login")
        #expect(created.document.body.hasSuffix("## Questions\n\n## Log\n"))
    }

    @Test func givenTicketAndBranchWin() async throws {
        let created = try await UseCases(ports: ports).startTask.execute(in: project, title: "Fix login", ticket: "ABC-7", branch: "bugfix/login")

        #expect(created.document.path.rawValue == "Notes/ABC-7 Fix login/ABC-7 Fix login.md")
        #expect(created.document.header.branch == "bugfix/login")
    }

    @Test func takenFolderNameGetsANumber() async throws {
        spies.files.seedFolder(FolderPath(rawValue: "Notes/Spike"))

        let created = try await UseCases(ports: ports).startTask.execute(in: project, title: "Spike")

        #expect(created.document.path.folder == "Notes/Spike 2")
        #expect(created.document.header.ticket == nil)
    }

    @Test func aFolderThatIsNotAProjectIsRefused() async throws {
        await #expect(throws: TaskError.notAProject("Inbox")) {
            try await UseCases(ports: ports).startTask.execute(in: SpaceName(rawValue: "Inbox"), title: "ABC-1 Fix")
        }
    }

    @Test func statusChangesOnlyOnATaskNote() async throws {
        let useCases = UseCases(ports: ports)
        let created = try await useCases.startTask.execute(in: project, title: "ABC-123 Fix login")

        try await useCases.setTaskStatus.execute(created.document.path, status: .review)

        #expect(spies.files.text(at: created.document.path)?.contains("status: review") == true)
        let plain = VaultPath(rawValue: "Notes/Plain.md")
        spies.files.seed(plain, "Just text")
        await #expect(throws: TaskError.notATask("Plain")) {
            try await useCases.setTaskStatus.execute(plain, status: .done)
        }
    }
}
