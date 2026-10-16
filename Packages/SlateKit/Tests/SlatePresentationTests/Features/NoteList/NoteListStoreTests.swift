import SlateDomain
import SlateMocks
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct NoteListStoreTests {
    private let spies: PortSpies
    private let navigator: Navigator
    private let activity = ActivityLog()
    private let events = AppEvents()
    private let store: NoteListStore

    init() {
        let (ports, spies) = Ports.spies(keyValues: InMemoryKeyValueStore())
        self.spies = spies
        spies.index.summariesResult = NoteSummaryFixture.notes
        spies.config.spacesResult = NoteSummaryFixture.spaces
        navigator = Navigator(store: ports.keyValues)
        store = NoteListStore(index: ports.index, config: ports.config, navigator: navigator, activity: activity, events: events)
    }

    @Test func refreshLoadsSpacesAndSummaries() async {
        await store.refresh()

        #expect(store.spaces == NoteSummaryFixture.spaces)
        #expect(store.summaries == NoteSummaryFixture.notes)
        #expect(store.isLoading == false)
        #expect(store.failure == nil)
        #expect(spies.index.calls == [.summaries(space: nil)])
    }

    @Test func refreshFailureIsShownAndLogged() async {
        spies.index.summariesError = .scripted("disk gone")

        await store.refresh()

        #expect(store.failure != nil)
        #expect(activity.events.map(\.title) == ["Cannot read the notes"])
        #expect(activity.events.first?.outcome == .failure)
    }

    @Test func pinnedNotesComeFirstThenNewest() async {
        await store.refresh()

        #expect(store.visibleNotes.map(\.id.rawValue) == ["b", "c", "d", "a"])
    }

    @Test func showingASpaceFiltersTheList() async {
        await store.refresh()

        store.show(space: NoteSummaryFixture.tasks)

        #expect(store.visibleNotes.map(\.id.rawValue) == ["c", "d"])
        #expect(store.spaceTitle == "Tasks")
        #expect(store.count(in: NoteSummaryFixture.tasks) == 2)
        #expect(store.count(in: nil) == 4)
    }

    @Test func showingAnotherSpaceSelectsItsFirstNote() async {
        await store.refresh()
        store.select(NoteID(rawValue: "a"))

        store.show(space: NoteSummaryFixture.tasks)

        #expect(navigator.selectedNote == NoteID(rawValue: "c"))
    }

    @Test func showingAllNotesKeepsTheSelection() async {
        await store.refresh()
        store.show(space: NoteSummaryFixture.tasks)
        store.select(NoteID(rawValue: "d"))

        store.show(space: nil)

        #expect(navigator.selectedNote == NoteID(rawValue: "d"))
        #expect(store.spaceTitle == "All notes")
    }

    @Test func filterTextMatchesTitlesWithoutCase() async {
        await store.refresh()

        store.filterText = "  CRASH "

        #expect(store.visibleNotes.map(\.id.rawValue) == ["c"])
    }

    @Test func selectedReturnsTheSummaryForTheNavigatorSelection() async {
        await store.refresh()

        store.select(NoteID(rawValue: "d"))

        #expect(store.selected?.title == "Update the text")
    }

    @Test func indexUpdatedEventRefreshes() async throws {
        events.post(.indexUpdated)

        try await waitUntil { store.summaries.count == 4 }
        #expect(spies.config.calls == [.spaces])
    }
}
