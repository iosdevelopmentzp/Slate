import SlateDomain
import SlateUI
import Testing
@testable import SlatePresentation

@Suite struct NoteRowMapperTests {
    @Test func plainNoteHasNoBadgesAndNoStatus() {
        let summary = NoteSummaryFixture.note("a", path: "Inbox/Idea.md", title: "Idea")

        let model = NoteRowMapper.model(for: summary, now: NoteSummaryFixture.now)

        #expect(model.title == "Idea")
        #expect(model.badges.isEmpty)
        #expect(model.status == nil)
        #expect(model.date.isEmpty == false)
    }

    @Test func taskNoteShowsTicketAttachmentsAndTodos() {
        let summary = NoteSummaryFixture.note(
            "c",
            path: "Tasks/Fix.md",
            status: .review,
            ticket: "ABC-123",
            openTodos: 2,
            attachmentCount: 1
        )

        let model = NoteRowMapper.model(for: summary, now: NoteSummaryFixture.now)

        #expect(model.badges.map(\.text) == ["ABC-123", "1", "2"])
        #expect(model.badges.map(\.systemImage) == ["ticket", "paperclip", "checklist"])
        #expect(model.badges.map(\.hint) == [nil, "1 image or file", "2 open checkboxes"])
        #expect(model.status == .orange)
        #expect(model.statusHint == "In review")
    }

    @Test func emptyTitleReadsUntitled() {
        let summary = NoteSummaryFixture.note("a", path: "Inbox/x.md", title: "")

        #expect(NoteRowMapper.model(for: summary, now: NoteSummaryFixture.now).title == "Untitled")
    }

    @Test func pinnedFlagIsCarried() {
        let summary = NoteSummaryFixture.note("b", path: "Inbox/Welcome.md", pinned: true)

        #expect(NoteRowMapper.model(for: summary, now: NoteSummaryFixture.now).isPinned)
    }
}
