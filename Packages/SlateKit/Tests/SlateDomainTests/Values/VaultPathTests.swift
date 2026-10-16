import Testing
@testable import SlateDomain

@Suite struct VaultPathTests {
    @Test func spaceIsTheFirstFolder() {
        let path = VaultPath(rawValue: "Tasks/ABC-123 Fix the crash.md")

        #expect(path.space == SpaceName(rawValue: "Tasks"))
        #expect(path.stem == "ABC-123 Fix the crash")
    }

    @Test func fileAtTheRootHasNoSpace() {
        let path = VaultPath(rawValue: "README.md")

        #expect(path.space == nil)
        #expect(path.stem == "README")
    }

    @Test func nestedNoteKeepsItsTopLevelSpace() {
        let path = VaultPath(rawValue: "Notes/Swift/Actors.md")

        #expect(path.space == SpaceName(rawValue: "Notes"))
        #expect(path.stem == "Actors")
    }
}
