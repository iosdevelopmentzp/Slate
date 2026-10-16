import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct DailyStoreTests {
    private let harness = StoreHarness()

    @Test func todayIsMadeAndSelected() async throws {
        await harness.daily.openToday()

        let today = try #require(harness.spies.index.indexed[VaultPath(rawValue: "Daily/2027-01-15.md")])
        #expect(harness.navigator.selectedNote == today.id)
        #expect(harness.posted.contains(.noteCreated(today.id, caret: "## Log\n\n".utf16.count)))
    }

    @Test func previousAndNextDayFollowTheOpenDaily() async throws {
        await harness.daily.openToday()
        await harness.noteList.refresh()

        await harness.daily.openDay(-1)

        let yesterday = try #require(harness.spies.index.indexed[VaultPath(rawValue: "Daily/2027-01-14.md")])
        #expect(harness.navigator.selectedNote == yesterday.id)
    }

    @Test func dayStepsNeedADailyNote() async throws {
        harness.seed("Notes/A.md", id: "a", title: "A")
        try await harness.index()
        await harness.noteList.refresh()
        harness.navigator.select(NoteID(rawValue: "a"))

        await harness.daily.openDay(1)

        #expect(harness.navigator.selectedNote == NoteID(rawValue: "a"))
    }

    @Test func dailyNotesOffShowsAHint() async {
        DailySettings(isEnabled: false).save(to: harness.keyValues)

        await harness.daily.openToday()

        #expect(harness.toaster.text == "Daily notes are off. Turn them on in Settings → General.")
        #expect(harness.navigator.selectedNote == nil)
    }
}
