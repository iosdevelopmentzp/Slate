import SlateDomain
import Testing
@testable import SlatePresentation

@Suite struct ListSourceTests {
    @Test func storedValueRoundTrips() {
        for source in [ListSource.all, .trash, .space(SpaceName(rawValue: "My Notes")), .folder(FolderPath(rawValue: "Work/Clients"))] {
            #expect(ListSource(storedValue: source.storedValue) == source)
        }
    }

    @Test func unknownValueMeansAll() {
        #expect(ListSource(storedValue: nil) == .all)
        #expect(ListSource(storedValue: "weird") == .all)
    }

    @Test func aFolderShowsOnlyItsOwnNotes() {
        let source = ListSource.folder(FolderPath(rawValue: "Work/Clients"))

        #expect(source.space == SpaceName(rawValue: "Work"))
        #expect(source.shows(VaultPath(rawValue: "Work/Clients/A.md")))
        #expect(source.shows(VaultPath(rawValue: "Work/Clients/2026/A.md")) == false)
        #expect(source.shows(VaultPath(rawValue: "Work/B.md")) == false)
        #expect(ListSource.space(SpaceName(rawValue: "Work")).shows(VaultPath(rawValue: "Work/Clients/A.md")) == false)
        #expect(ListSource.all.shows(VaultPath(rawValue: "Work/Clients/A.md")))
        #expect(ListSource.showing(FolderPath(rawValue: "Work")) == .space(SpaceName(rawValue: "Work")))
    }
}
