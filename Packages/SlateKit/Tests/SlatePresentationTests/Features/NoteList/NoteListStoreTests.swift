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

    @Test func openSelectsANoteByPathAndShowsItsFolder() async throws {
        let path = harness.seed("Notes/Sub/B.md", id: "b")
        try await harness.index()
        await store.refresh()
        harness.navigator.show(.space(SpaceName(rawValue: "Inbox")))

        store.open(path)
        store.open(VaultPath(rawValue: "Notes/Missing.md"))

        #expect(harness.navigator.selectedNote == NoteID(rawValue: "b"))
        #expect(harness.navigator.source == .folder(FolderPath(rawValue: "Notes/Sub")))
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
        #expect(harness.toaster.actionTitle == "Undo")
    }

    @Test func undoMovesTheNoteBack() async throws {
        let path = harness.seed("Inbox/A.md", id: "a")
        try await harness.index()
        await store.refresh()
        await store.moveNote(try #require(store.summaries.first), to: SpaceName(rawValue: "Notes"))

        harness.toaster.performAction()

        try await waitUntil { harness.spies.files.paths == [path] }
        #expect(harness.posted.contains(.noteMoved(from: VaultPath(rawValue: "Notes/A.md"), to: path)))
    }

    @Test func dropMovesTheNoteByItsID() async throws {
        harness.seed("Inbox/A.md", id: "a")
        try await harness.index()
        await store.refresh()

        await store.moveNote(id: NoteID(rawValue: "a"), to: SpaceName(rawValue: "Notes"))
        await store.moveNote(id: NoteID(rawValue: "unknown"), to: SpaceName(rawValue: "Notes"))

        #expect(harness.spies.files.paths == [VaultPath(rawValue: "Notes/A.md")])
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

    @Test func aFolderListsOnlyItsOwnNotes() async throws {
        harness.seed("Notes/A.md", id: "a")
        harness.seed("Notes/Swift/B.md", id: "b")
        harness.seed("Notes/Swift/Actors/C.md", id: "c")
        try await harness.index()
        await store.refresh()

        store.show(.space(SpaceName(rawValue: "Notes")))
        #expect(store.visibleNotes.map(\.id.rawValue) == ["a"])

        store.show(.folder(FolderPath(rawValue: "Notes/Swift")))
        #expect(store.visibleNotes.map(\.id.rawValue) == ["b"])
        #expect(store.count(in: FolderPath(rawValue: "Notes/Swift")) == 2)

        store.show(.all)
        #expect(store.visibleNotes.count == 3)
    }

    @Test func aNewNoteGoesIntoTheShownSubFolder() async throws {
        harness.navigator.show(.folder(FolderPath(rawValue: "Notes/Swift")))

        await store.createNote()

        #expect(harness.spies.files.paths.map(\.folder) == ["Notes/Swift"])
        #expect(harness.navigator.source == .folder(FolderPath(rawValue: "Notes/Swift")))
    }

    @Test func aNoteMovesIntoASubFolderAndUndoTakesItBack() async throws {
        let path = harness.seed("Notes/A.md", id: "a")
        try await harness.index()
        await store.refresh()

        await store.moveNote(id: NoteID(rawValue: "a"), toFolder: FolderPath(rawValue: "Notes/Swift"))

        #expect(harness.spies.files.paths == [VaultPath(rawValue: "Notes/Swift/A.md")])
        #expect(harness.toaster.text == "Moved to Swift")
        harness.toaster.performAction()
        try await waitUntil { harness.spies.files.paths == [path] }
    }

    @Test func copyPathAndCopyLinkPutTheNoteOnThePasteboard() async throws {
        harness.seed("Notes/Groceries.md", id: "g")
        try await harness.index()
        let summary = try #require(try await harness.ports.index.summary(id: NoteID(rawValue: "g")))

        harness.noteList.copyPath(summary)
        harness.noteList.copyLink(summary)

        #expect(harness.copied == ["/vault/Notes/Groceries.md", "slate://open?id=g"])
        #expect(harness.toaster.text == "Link copied")
        #expect(harness.noteList.fileURL(for: summary).path == "/vault/Notes/Groceries.md")
    }
}
