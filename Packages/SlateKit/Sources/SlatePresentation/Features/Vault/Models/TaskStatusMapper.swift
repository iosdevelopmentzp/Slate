import Foundation
import SlateDomain
import SlateUI

enum TaskStatusMapper {
    static func tag(for status: NoteStatus) -> TagModel {
        TagModel(title(status), tint: tint(status))
    }

    static func title(_ status: NoteStatus) -> String {
        switch status {
        case .todo: "To do"
        case .active: "In progress"
        case .review: "In review"
        case .done: "Done"
        case .dropped: "Dropped"
        }
    }

    static func tint(_ status: NoteStatus) -> Tint {
        switch status {
        case .todo: .gray
        case .active: .blue
        case .review: .orange
        case .done: .green
        case .dropped: .secondary
        }
    }

    static func rank(_ status: NoteStatus?) -> Int {
        switch status {
        case .active: 0
        case .review: 1
        case .todo, nil: 2
        case .done: 3
        case .dropped: 4
        }
    }

    static func taskNote(in folder: FolderPath, among summaries: [NoteSummary]) -> NoteSummary? {
        let tasks = summaries.filter { $0.path.folder == folder.rawValue && $0.type == NoteType.task.name }
        return tasks.first { StemPolicy.isSame($0.stem, folder.name) } ?? tasks.first
    }
}
