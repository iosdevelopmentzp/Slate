import Foundation
import SlateDomain
import SlateMocks
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct NoteListStoreTests {
    private let harness = StoreHarness()

    private var store: NoteListStore {
        harness.noteList
    }

    private func seedFour() async throws {
        harness.seed("Inbox/Old idea.md", id: "a")
        harness.seed("Inbox/Welcome.md", id: "b", pinned: true)
        harness.seed("Tasks/Fix the crash.md", id: "c", type: "task")
        harness.seed("Tasks/Update the text.md", id: "d", type: "task")
        try await harness.index()
    }

    private func id(_ raw: String) -> NoteID {
        NoteID(rawValue: raw)
    }

    @Test func refreshLoadsTheIndex() async throws {
        try await seedFour()

        await store.refresh()

        #expect(store.summaries.count == 4)
        #expect(store.isLoading == false)
        #expect(store.failure == nil)
    }

    @Test func refreshFailureIsShownAndLogged() async {
        harness.spies.index.summariesError = .scripted("disk gone")

        await store.refresh()

        #expect(store.failure != nil)
        #expect(harness.activity.events.map(\.title) == ["Cannot read the notes"])
    }

    @Test func pinnedNotesComeFirstThenTheChosenSort() async throws {
        try await seedFour()
        await store.refresh()

        #expect(store.visibleNotes.map(\.id.rawValue) == ["b", "d", "c", "a"])

        store.sort = .title
        #expect(store.visibleNotes.map(\.id.rawValue) == ["b", "c", "a", "d"])
        #expect(harness.keyValues.string(forKey: "list.sort") == "title")
    }

    @Test func showingASpaceFiltersAndMovesTheSelection() async throws {
        try await seedFour()
        await store.refresh()
        store.select(id("a"))

        store.show(.space(SpaceName(rawValue: "Tasks")))

        #expect(Set(store.visibleNotes.map(\.id.rawValue)) == ["c", "d"])
        #expect(harness.navigator.selectedNote == store.visibleNotes.first?.id)
        #expect(store.count(in: SpaceName(rawValue: "Tasks")) == 2)
        #expect(store.count(in: nil) == 4)
    }

    @Test func showingAllNotesKeepsTheSelection() async throws {
        try await seedFour()
        await store.refresh()
        store.show(.space(SpaceName(rawValue: "Tasks")))
        store.select(id("d"))

        store.show(.all)

        #expect(harness.navigator.selectedNote == id("d"))
    }

    @Test func filterTextMatchesTitlesWithoutCase() async throws {
        try await seedFour()
        await store.refresh()

        store.filterText = "  CRASH "

        #expect(store.visibleNotes.map(\.id.rawValue) == ["c"])
    }

    @Test func newNoteGoesIntoTheCurrentSpaceAndIsSelected() async throws {
        store.show(.space(SpaceName(rawValue: "Notes")))

        await store.createNote()

        let path = VaultPath(rawValue: "Notes/Untitled.md")
        #expect(harness.spies.files.paths == [path])
        let created = try #require(store.summaries.first)
        #expect(harness.navigator.selectedNote == created.id)
        #expect(harness.posted.contains(.noteCreated(created.id, caret: 0)))
    }

    @Test func newTaskGoesToTasksAndShowsTasks() async throws {
        store.show(.space(SpaceName(rawValue: "Inbox")))

        await store.createNote(type: "task")

        #expect(harness.spies.files.paths == [VaultPath(rawValue: "Tasks/Untitled.md")])
        #expect(store.source == .space(SpaceName(rawValue: "Tasks")))
    }

    @Test func pinWritesTheHeaderAndAnnouncesTheChange() async throws {
        let path = harness.seed("Inbox/A.md", id: "a")
        try await harness.index()
        await store.refresh()
        let summary = try #require(store.summaries.first)

        await store.togglePin(summary)

        #expect(try await harness.document(at: path).header.pinned == true)
        #expect(store.summaries.first?.pinned == true)
        #expect(harness.posted.contains(.vaultChanged([path])))
    }

    @Test func moveAnnouncesTheNewPathAndShowsAToast() async throws {
        let path = harness.seed("Inbox/A.md", id: "a")
        try await harness.index()
        await store.refresh()

        await store.moveNote(try #require(store.summaries.first), to: SpaceName(rawValue: "Notes"))

        let target = VaultPath(rawValue: "Notes/A.md")
        #expect(harness.spies.files.paths == [target])
        #expect(harness.posted.contains(.noteMoved(from: path, to: target)))
        #expect(harness.toaster.text == "Moved to Notes")
    }

    @Test func archiveMovesToTheArchiveSpace() async throws {
        harness.seed("Inbox/A.md", id: "a")
        try await harness.index()
        await store.refresh()

        await store.archiveNote(try #require(store.summaries.first))

        #expect(harness.spies.files.paths == [VaultPath(rawValue: "Archive/A.md")])
    }

    @Test func duplicateSelectsTheCopy() async throws {
        harness.seed("Inbox/A.md", id: "a", body: "Body")
        try await harness.index()
        await store.refresh()

        await store.duplicateNote(try #require(store.summaries.first))

        let copy = try #require(store.summaries.first { $0.path == VaultPath(rawValue: "Inbox/A 2.md") })
        #expect(harness.navigator.selectedNote == copy.id)
    }

    @Test func trashNeedsAConfirmationThenSelectsTheNextNoteAndOffersUndo() async throws {
        try await seedFour()
        await store.refresh()
        store.show(.space(SpaceName(rawValue: "Inbox")))
        store.select(id("b"))
        let pinned = try #require(store.selected)

        store.requestTrash(pinned.id)
        #expect(store.confirmingTrash == pinned.id)
        await store.confirmTrash(pinned)

        #expect(store.confirmingTrash == nil)
        #expect(harness.spies.files.paths.contains(pinned.path) == false)
        #expect(harness.navigator.selectedNote == id("a"))
        #expect(harness.posted.contains(.noteTrashed(pinned.path)))
        #expect(harness.toaster.text == "Moved to the Trash")
        #expect(harness.toaster.actionTitle == "Undo")

        harness.toaster.performAction()
        try await waitUntil { store.summaries.contains { $0.path == pinned.path } }
        #expect(harness.spies.files.paths.contains(pinned.path))
    }

    @Test func cancelTrashClearsTheConfirmation() async throws {
        store.requestTrash(id("a"))

        store.cancelTrash()

        #expect(store.confirmingTrash == nil)
    }

    @Test func trashSourceListsTrashedNotesAndRestoresThem() async throws {
        harness.seed("Inbox/A.md", id: "a")
        try await harness.index()
        await store.refresh()
        let item = try await harness.useCases.trash.execute(VaultPath(rawValue: "Inbox/A.md"))

        store.show(.trash)
        try await waitUntil { store.trashItems == [item] }
        #expect(store.visibleNotes.isEmpty)

        await store.restoreItem(item)

        #expect(store.trashItems.isEmpty)
        #expect(harness.toaster.text == "Restored to Inbox")
    }

    @Test func indexUpdatedEventRefreshes() async throws {
        harness.seed("Inbox/A.md", id: "a")
        try await harness.index()
        _ = store

        harness.events.post(.indexUpdated)

        try await waitUntil { store.summaries.count == 1 }
    }
}
