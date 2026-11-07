import Foundation

package struct OpenQuestion: Equatable, Sendable {
    package let number: Int
    package let title: String
    package let text: String
    package let line: Int

    package init(number: Int, title: String, text: String, line: Int) {
        self.number = number
        self.title = title
        self.text = text
        self.line = line
    }
}
