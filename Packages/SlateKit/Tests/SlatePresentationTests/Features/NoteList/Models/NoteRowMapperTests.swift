import Foundation
import SlateDomain
import SlateUI
import Testing
@testable import SlatePresentation

@Suite struct NoteRowMapperTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func summary(path: String = "Inbox/Idea.md", title: String = "Idea", type: String = "note", status: NoteStatus? = nil, ticket: String? = nil, pinned: Bool = false, openTodos: Int = 0, attachments: Int = 0) -> NoteSummary {
        NoteSummary(id: NoteID(rawValue: "a"), path: VaultPath(rawValue: path), title: title, type: type, status: status, ticket: ticket, pinned: pinned, updated: now.addingTimeInterval(-60), preview: "p", openTodos: openTodos, attachmentCount: attachments)
    }

    @Test func plainNoteHasNoTypeIconBadgesOrStatus() {
        let model = NoteRowMapper.model(for: summary(), type: .note, now: now)

        #expect(model.title == "Idea")
        #expect(model.typeIcon == nil)
        #expect(model.badges.isEmpty)
        #expect(model.status == nil)
        #expect(model.date.isEmpty == false)
    }

    @Test func taskShowsItsTypeTicketAttachmentsAndTodos() {
        let model = NoteRowMapper.model(for: summary(type: "task", status: .review, ticket: "ABC-123", openTodos: 2, attachments: 1), type: .task, now: now)

        #expect(model.typeIcon == "checkmark.circle")
        #expect(model.typeTitle == "Task")
        #expect(model.badges.map(\.text) == ["ABC-123", "1", "2"])
        #expect(model.badges.map(\.systemImage) == ["ticket", "paperclip", "checklist"])
        #expect(model.badges.map(\.hint) == [nil, "1 image or file", "2 open checkboxes"])
        #expect(model.status == .orange)
        #expect(model.statusHint == "In review")
    }

    @Test func noteInASubfolderShowsTheSubfolder() {
        let model = NoteRowMapper.model(for: summary(path: "Notes/Swift/Actors.md"), type: .note, now: now)

        #expect(model.badges.map(\.text) == ["Swift"])
    }

    @Test func unknownTypeStillGetsAnIcon() {
        let model = NoteRowMapper.model(for: summary(type: "bug"), type: nil, now: now)

        #expect(model.typeIcon == "doc")
        #expect(model.typeTitle == "Bug")
    }

    @Test func emptyTitleReadsUntitledAndPinIsCarried() {
        let model = NoteRowMapper.model(for: summary(title: "", pinned: true), type: .note, now: now)

        #expect(model.title == "Untitled")
        #expect(model.isPinned)
    }
}
