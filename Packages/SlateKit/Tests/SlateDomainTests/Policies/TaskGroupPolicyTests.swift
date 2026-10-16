import Foundation
import Testing
@testable import SlateDomain

@Suite struct TaskGroupPolicyTests {
    @Test func statusesFallIntoThreeGroups() {
        #expect(TaskGroupPolicy.group(for: .active) == .active)
        #expect(TaskGroupPolicy.group(for: .review) == .active)
        #expect(TaskGroupPolicy.group(for: .todo) == .todo)
        #expect(TaskGroupPolicy.group(for: nil) == .todo)
        #expect(TaskGroupPolicy.group(for: .dropped) == .done)
    }

    @Test func groupedKeepsTheOrderAndDropsEmptyGroups() {
        let notes = [NoteStatus.done, .active, .todo, .review].enumerated().map { index, status in
            NoteSummary(id: NoteID(rawValue: "\(index)"), path: VaultPath(rawValue: "Tasks/\(index).md"), title: "\(index)", status: status, updated: Date(), preview: "")
        }

        let groups = TaskGroupPolicy.grouped(notes)

        #expect(groups.map(\.group) == [.active, .todo, .done])
        #expect(groups[0].notes.map(\.id.rawValue) == ["1", "3"])
    }
}
