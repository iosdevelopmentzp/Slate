import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct LinkRepositoryUseCaseTests {
    @Test func theMainCheckoutAndTheRemoteAreStored() async throws {
        let (ports, spies) = Ports.spies()
        let useCases = UseCases(ports: ports)
        let notes = SpaceName(rawValue: "Notes")
        try await useCases.setProject.execute(notes, project: ProjectInfo(id: "p", repositories: ["/old"]))
        spies.repositories.result = RepositoryInfo(root: "/dev/wt", mainRoot: "/dev/myapp", remote: "git@gitlab.example.com:group/myapp.git")

        let info = try await useCases.linkRepository.execute(notes, directory: URL(fileURLWithPath: "/dev/wt"))

        #expect(info.repositories == ["/dev/myapp", "/old"])
        #expect(info.remote == "git@gitlab.example.com:group/myapp.git")
        #expect(spies.config.config.space(notes)?.project == info)
    }

    @Test func aFolderWithoutGitIsStoredAsItIs() async throws {
        let (ports, spies) = Ports.spies()
        let useCases = UseCases(ports: ports)
        let notes = SpaceName(rawValue: "Notes")
        try await useCases.setProject.execute(notes, project: ProjectInfo(id: "p"))

        let info = try await useCases.linkRepository.execute(notes, directory: URL(fileURLWithPath: "/dev/plain"))

        #expect(info.repositories == ["/dev/plain"])
        #expect(info.remote == nil)
        #expect(spies.repositories.inspected == [URL(fileURLWithPath: "/dev/plain")])
    }

    @Test func onlyAProjectCanBeLinked() async throws {
        let (ports, _) = Ports.spies()

        await #expect(throws: TaskError.notAProject("Inbox")) {
            try await UseCases(ports: ports).linkRepository.execute(SpaceName(rawValue: "Inbox"), directory: URL(fileURLWithPath: "/dev"))
        }
    }
}
