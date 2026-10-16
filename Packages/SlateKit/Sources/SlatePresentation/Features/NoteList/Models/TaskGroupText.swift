import Foundation
import SlateDomain

enum TaskGroupText {
    static func title(_ group: TaskGroupPolicy.Group) -> String {
        switch group {
        case .active: "Active"
        case .todo: "To do"
        case .done: "Done"
        }
    }
}
