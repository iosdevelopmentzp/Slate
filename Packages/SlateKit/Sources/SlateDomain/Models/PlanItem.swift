import Foundation

package struct PlanItem: Hashable, Sendable {
    package let number: Int
    package let text: String
    package let isDone: Bool

    package var label: String {
        text.hasPrefix("\(number).") ? text : "\(number). \(text)"
    }

    package init(number: Int, text: String, isDone: Bool) {
        self.number = number
        self.text = text
        self.isDone = isDone
    }
}
