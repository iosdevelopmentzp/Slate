import Foundation
import SlateDomain
import Testing
@testable import SlatePresentation

@Suite struct NoteRowMapperTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func summary(title: String = "Idea", pinned: Bool = false) -> NoteSummary {
        NoteSummary(id: NoteID(rawValue: "a"), path: VaultPath(rawValue: "Notes/Idea.md"), title: title, type: "note", pinned: pinned, updated: now.addingTimeInterval(-60), preview: "p")
    }

    @Test func noteShowsTitlePreviewAndDate() {
        let model = NoteRowMapper.model(for: summary(), now: now)

        #expect(model.title == "Idea")
        #expect(model.preview == "p")
        #expect(model.date.isEmpty == false)
        #expect(model.isPinned == false)
    }

    @Test func emptyTitleReadsUntitledAndPinIsCarried() {
        let model = NoteRowMapper.model(for: summary(title: "", pinned: true), now: now)

        #expect(model.title == "Untitled")
        #expect(model.isPinned)
    }
}
