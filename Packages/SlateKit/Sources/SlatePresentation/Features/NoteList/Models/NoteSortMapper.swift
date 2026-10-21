import Foundation
import SlateDomain

enum NoteSortMapper {
    static func title(for sort: NoteSort) -> String {
        switch sort {
        case .updated: "Date Edited"
        case .created: "Date Created"
        case .title: "Title"
        }
    }

    static func hint(for sort: NoteSort) -> String {
        "Sort notes: \(title(for: sort))"
    }
}
