import Foundation
import SlateDomain
import SlateUI
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct TaskStatusMapperTests {
    @Test func everyStatusHasItsOwnTint() {
        #expect(NoteStatus.allCases.map(TaskStatusMapper.tint) == [.gray, .blue, .orange, .green, .secondary])
        #expect(TaskStatusMapper.tag(for: .active) == TagModel("In progress", tint: .blue))
    }

    @Test func workInProgressComesFirstAndFinishedWorkLast() {
        let ranks = [NoteStatus.done, .todo, .review, .active, .dropped].map(TaskStatusMapper.rank)

        #expect(ranks == [3, 2, 1, 0, 4])
        #expect(TaskStatusMapper.rank(nil) == TaskStatusMapper.rank(.todo))
    }

    @Test func theTaskNoteNamedLikeItsFolderIsChosen() {
        let folder = FolderPath(rawValue: "MyApp/ABC-1 Fix")
        let other = NoteSummary(id: NoteID(rawValue: "o"), path: VaultPath(rawValue: "MyApp/ABC-1 Fix/Other.md"), title: "Other", type: "task", updated: .now, preview: "")
        let main = NoteSummary(id: NoteID(rawValue: "m"), path: VaultPath(rawValue: "MyApp/ABC-1 Fix/ABC-1 Fix.md"), title: "ABC-1 Fix", type: "task", status: .review, updated: .now, preview: "")
        let deeper = NoteSummary(id: NoteID(rawValue: "d"), path: VaultPath(rawValue: "MyApp/ABC-1 Fix/Old/ABC-1 Fix.md"), title: "ABC-1 Fix", type: "task", updated: .now, preview: "")

        #expect(TaskStatusMapper.taskNote(in: folder, among: [other, deeper, main])?.id == main.id)
        #expect(TaskStatusMapper.taskNote(in: folder, among: [deeper]) == nil)
    }

    @Test func taskFolderRowCarriesStatusAndTicket() {
        let folder = FolderPath(rawValue: "MyApp/ABC-1 Fix")
        let note = NoteSummary(id: NoteID(rawValue: "m"), path: VaultPath(rawValue: "MyApp/ABC-1 Fix/ABC-1 Fix.md"), title: "ABC-1 Fix", type: "task", status: .done, ticket: "ABC-1", updated: .now, preview: "")

        let model = FolderRowMapper.model(forTask: folder, space: nil, count: 2, note: note)
        let plain = FolderRowMapper.model(forTask: folder, space: nil, count: 2, note: nil)

        #expect(model.status == TagModel("Done", tint: .green))
        #expect(model.ticket == "ABC-1")
        #expect(model.statusRank == 3)
        #expect(plain.status == nil)
    }

    @Test func taskLineShowsOnlyForATaskNoteInAProject() {
        let header = NoteHeader(type: "task", ticket: "ABC-1", branch: "", status: "review")

        let model = TaskLineMapper.model(for: header, inProject: true)

        #expect(model?.status == .review)
        #expect(model?.ticket == "ABC-1")
        #expect(model?.branch == nil)
        #expect(TaskLineMapper.model(for: header, inProject: false) == nil)
        #expect(TaskLineMapper.model(for: NoteHeader(type: "note"), inProject: true) == nil)
    }
}
