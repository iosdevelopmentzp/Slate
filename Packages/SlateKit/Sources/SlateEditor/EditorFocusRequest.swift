import Foundation

package struct EditorFocusRequest: Equatable, Sendable {
    package let token: Int
    package let atStart: Bool
    package let words: [String]
    package let heading: String?

    package init(token: Int, atStart: Bool = false, words: [String] = [], heading: String? = nil) {
        self.token = token
        self.atStart = atStart
        self.words = words
        self.heading = heading
    }
}
