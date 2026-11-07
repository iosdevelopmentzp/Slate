import Testing
import SlateDomain
import SlateEditor
@testable import SlatePresentation

@MainActor
@Suite struct ReferenceKindsMapperTests {
    @Test func aNoteOutsideAProjectOnlyGetsTickets() {
        #expect(ReferenceKindsMapper.kinds(project: nil, ticketAddress: "https://example.atlassian.net/browse/") == [.tickets])
        #expect(ReferenceKindsMapper.kinds(project: nil, ticketAddress: "").isEmpty)
    }

    @Test func aProjectWithARepositoryAndARemoteGetsTheRest() {
        let project = ProjectInfo(repositories: ["/code/app"], remote: "gitlab.example.com/group/app")

        #expect(ReferenceKindsMapper.kinds(project: project, ticketAddress: "") == [.files, .mergeRequests, .commits])
        #expect(ReferenceKindsMapper.kinds(project: ProjectInfo(), ticketAddress: "").isEmpty)
    }
}
