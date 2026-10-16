import Foundation

package struct EditorLinkPattern: Equatable, Sendable {
    package let id: String
    package let regex: String

    package init(id: String, regex: String) {
        self.id = id
        self.regex = regex
    }
}
