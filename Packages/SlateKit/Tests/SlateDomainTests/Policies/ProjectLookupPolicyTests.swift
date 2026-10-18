import Foundation
import Testing
@testable import SlateDomain

@Suite struct ProjectLookupPolicyTests {
    private let spaces = [
        Space(folder: SpaceName(rawValue: "Notes")),
        Space(folder: SpaceName(rawValue: "MyApp"), project: ProjectInfo(id: "a", repositories: ["/dev/myapp"])),
        Space(folder: SpaceName(rawValue: "Site"), project: ProjectInfo(id: "b", remote: "https://gitlab.example.com/group/site.git")),
    ]

    @Test func aDirectoryInsideALinkedRepositoryFindsItsProject() {
        #expect(ProjectLookupPolicy.project(for: "/dev/myapp/Sources/App", repository: nil, among: spaces)?.folder.rawValue == "MyApp")
        #expect(ProjectLookupPolicy.project(for: "/dev/myapp-old", repository: nil, among: spaces) == nil)
    }

    @Test func aWorktreeFindsTheProjectOfItsMainCheckout() {
        let worktree = RepositoryInfo(root: "/dev/wt/abc", mainRoot: "/dev/myapp")

        #expect(ProjectLookupPolicy.project(for: "/dev/wt/abc", repository: worktree, among: spaces)?.folder.rawValue == "MyApp")
    }

    @Test func theRemoteFindsAProjectInAnyForm() {
        let clone = RepositoryInfo(root: "/tmp/site", remote: "git@gitlab.example.com:group/site.git")

        #expect(ProjectLookupPolicy.project(for: "/tmp/site", repository: clone, among: spaces)?.folder.rawValue == "Site")
    }

    @Test func remotesAreComparedWithoutSchemeUserPortAndSuffix() {
        let forms = [
            "git@gitlab.example.com:group/site.git",
            "https://gitlab.example.com/group/site",
            "ssh://git@gitlab.example.com/group/site.git/",
            "HTTPS://GitLab.example.com/Group/Site.git",
        ]

        #expect(Set(forms.compactMap(ProjectLookupPolicy.normalizedRemote)) == ["gitlab.example.com/group/site"])
        #expect(ProjectLookupPolicy.normalizedRemote("  ") == nil)
    }

    @Test func aFolderThatIsNotAProjectIsNeverFound() {
        let notes = [Space(folder: SpaceName(rawValue: "Notes"))]

        #expect(ProjectLookupPolicy.project(for: "/dev/myapp", repository: RepositoryInfo(root: "/dev/myapp"), among: notes) == nil)
    }
}
