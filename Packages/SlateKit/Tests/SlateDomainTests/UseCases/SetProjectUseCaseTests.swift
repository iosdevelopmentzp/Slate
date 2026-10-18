import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct SetProjectUseCaseTests {
    @Test func folderBecomesAProjectWithItsIconAndAgentsMayWriteThere() async throws {
        let (ports, spies) = Ports.spies()
        let project = ProjectInfo(id: "p1", repositories: ["/tmp/myapp"])
        spies.config.config.spaces[0].icon = "folder.fill"

        let space = try await UseCases(ports: ports).setProject.execute(SpaceName(rawValue: "Inbox"), project: project)

        #expect(space.project == project)
        #expect(space.icon == SetProjectUseCase.projectIcon)
        #expect(spies.config.config.space(SpaceName(rawValue: "Inbox"))?.project == project)
        #expect(spies.config.permissions.canWrite(in: FolderPath(rawValue: "Inbox")))
    }

    @Test func projectBecomesAFolderAgainAndKeepsAChosenIcon() async throws {
        let (ports, spies) = Ports.spies()
        let useCases = UseCases(ports: ports)
        let inbox = SpaceName(rawValue: "Inbox")
        spies.config.config.spaces[0].icon = "star.fill"
        try await useCases.setProject.execute(inbox, project: ProjectInfo(id: "p1"))

        let space = try await useCases.setProject.execute(inbox, project: nil)

        #expect(space.project == nil)
        #expect(space.icon == "star.fill")
    }

    @Test func plainFolderIconComesBackWhenTheProjectIsUndone() async throws {
        let (ports, spies) = Ports.spies()
        let useCases = UseCases(ports: ports)
        let notes = SpaceName(rawValue: "Notes")
        spies.config.config.spaces[2].icon = nil
        try await useCases.setProject.execute(notes, project: ProjectInfo(id: "p1"))

        let space = try await useCases.setProject.execute(notes, project: nil)

        #expect(space.icon == "folder.fill")
    }

    @Test func unknownFolderIsRejected() async throws {
        let (ports, _) = Ports.spies()

        await #expect(throws: VaultError.self) {
            try await UseCases(ports: ports).setProject.execute(SpaceName(rawValue: "Missing"), project: ProjectInfo())
        }
    }

    @Test func newProjectIsAFolderWithProjectDetails() async throws {
        let (ports, spies) = Ports.spies()

        let space = try await UseCases(ports: ports).createProject.execute(name: "MyApp", repositories: ["/tmp/myapp"])

        #expect(spies.files.folderNames.contains(FolderPath(space: space)))
        #expect(spies.config.config.space(space)?.project?.repositories == ["/tmp/myapp"])
        #expect(spies.config.config.space(space)?.icon == SetProjectUseCase.projectIcon)
    }
}
