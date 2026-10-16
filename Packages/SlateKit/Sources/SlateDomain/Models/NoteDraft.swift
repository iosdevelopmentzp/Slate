import Foundation

package struct NoteDraft: Hashable, Sendable {
    package var title: String?
    package var type: String?
    package var space: SpaceName?

    package init(title: String? = nil, type: String? = nil, space: SpaceName? = nil) {
        self.title = title
        self.type = type
        self.space = space
    }
}
