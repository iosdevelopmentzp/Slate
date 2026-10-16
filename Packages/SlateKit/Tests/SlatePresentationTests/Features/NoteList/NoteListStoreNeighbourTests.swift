import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct NoteListStoreNeighbourTests {
    private let harness = StoreHarness()

    @Test func nextAndPreviousFollowTheList() async throws {
        harness.seed("Notes/A.md", id: "a", title: "A")
        harness.seed("Notes/B.md", id: "b", title: "B")
        try await harness.index()
        await harness.noteList.refresh()
        harness.noteList.sort = .title

        harness.noteList.selectNeighbour(1)
        #expect(harness.navigator.selectedNote == NoteID(rawValue: "a"))
        harness.noteList.selectNeighbour(1)
        #expect(harness.navigator.selectedNote == NoteID(rawValue: "b"))
        harness.noteList.selectNeighbour(1)
        #expect(harness.navigator.selectedNote == NoteID(rawValue: "b"))
        harness.noteList.selectNeighbour(-1)
        #expect(harness.navigator.selectedNote == NoteID(rawValue: "a"))
    }
}
