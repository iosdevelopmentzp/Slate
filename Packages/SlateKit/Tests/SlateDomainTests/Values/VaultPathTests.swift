import Testing
@testable import SlateDomain

@Suite struct VaultPathTests {
    @Test func spaceIsTheFirstFolder() {
        let path = VaultPath(rawValue: "Tasks/ABC-123 Fix the crash.md")

        #expect(path.space == SpaceName(rawValue: "Tasks"))
        #expect(path.stem == "ABC-123 Fix the crash")
        #expect(path.folder == "Tasks")
        #expect(path.depth == 1)
        #expect(path.subfolder == nil)
        #expect(path.isNote)
    }

    @Test func fileAtTheRootHasNoSpace() {
        let path = VaultPath(rawValue: "README.md")

        #expect(path.space == nil)
        #expect(path.stem == "README")
        #expect(path.isNote == false)
    }

    @Test func nestedNoteKeepsItsTopLevelSpaceAndShowsTheSubfolder() {
        let path = VaultPath(rawValue: "Notes/Swift/Actors.md")

        #expect(path.space == SpaceName(rawValue: "Notes"))
        #expect(path.subfolder == "Swift")
        #expect(path.depth == 2)
    }

    @Test func hiddenAndUnderscoreFoldersAreNotSpaces() {
        #expect(VaultPath(rawValue: ".trash/Inbox/A.md").space == nil)
        #expect(VaultPath(rawValue: "_templates/task.md").isNote == false)
    }

    @Test func replacingTheStemKeepsTheFolder() {
        #expect(VaultPath(rawValue: "Notes/Swift/Old.md").replacingStem(with: "New") == VaultPath(rawValue: "Notes/Swift/New.md"))
    }

    @Test func buildsFromSpaceAndStem() {
        #expect(VaultPath(space: SpaceName(rawValue: "Inbox"), stem: "Hi") == VaultPath(rawValue: "Inbox/Hi.md"))
    }
}
