import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct BacklinksStoreTests {
    private let harness = StoreHarness()

    @Test func showingANoteLoadsItsBacklinksAndASaveRefreshesThem() async throws {
        let target = try await harness.useCases.create.execute(NoteDraft(title: "Plan", space: SpaceName(rawValue: "Notes")))
        _ = try await harness.useCases.create.execute(NoteDraft(title: "Daily", space: SpaceName(rawValue: "Notes"), body: "see [[Plan]]\n"))
        let store = harness.backlinks

        await store.show(target.document.path)
        #expect(store.backlinks.map(\.note.title) == ["Daily"])

        _ = try await harness.useCases.create.execute(NoteDraft(title: "Review", space: SpaceName(rawValue: "Notes"), body: "and [[Plan]]\n"))
        harness.events.post(.indexUpdated)
        try await waitUntil { store.backlinks.count == 2 }
    }

    @Test func openingABacklinkSelectsTheNote() {
        harness.backlinks.open(NoteID(rawValue: "b"))

        #expect(harness.navigator.selectedNote == NoteID(rawValue: "b"))
    }
}
