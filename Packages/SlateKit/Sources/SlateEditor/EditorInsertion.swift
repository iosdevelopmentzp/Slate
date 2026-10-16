import Foundation

package struct EditorInsertion: Equatable, Sendable {
    package let token: Int
    package let markdown: String

    package init(token: Int, markdown: String) {
        self.token = token
        self.markdown = markdown
    }
}
