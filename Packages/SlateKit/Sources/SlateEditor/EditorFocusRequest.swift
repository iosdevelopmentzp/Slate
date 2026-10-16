import Foundation

package struct EditorFocusRequest: Equatable, Sendable {
    package let token: Int
    package let caret: Int?

    package init(token: Int, caret: Int?) {
        self.token = token
        self.caret = caret
    }
}
