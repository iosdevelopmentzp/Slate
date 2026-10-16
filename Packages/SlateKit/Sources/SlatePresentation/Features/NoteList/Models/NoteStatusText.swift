import Foundation
import SlateDomain
import SlateUI

enum NoteStatusText {

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
        case .dropped: .red
        }
    }
}
