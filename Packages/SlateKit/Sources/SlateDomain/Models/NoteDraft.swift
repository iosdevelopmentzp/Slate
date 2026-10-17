import Foundation

package struct NoteDraft: Hashable, Sendable {
    package var title: String?
    package var type: String?
    package var space: SpaceName?
    package var ticket: String?
    package var body: String?
    package var bodyPrefix: String?
    package var template: String?
    package var folder: FolderPath?

    package init(title: String? = nil, type: String? = nil, space: SpaceName? = nil, ticket: String? = nil, body: String? = nil, bodyPrefix: String? = nil, template: String? = nil, folder: FolderPath? = nil) {
        self.title = title
        self.type = type
        self.space = space
        self.ticket = ticket
        self.body = body
        self.bodyPrefix = bodyPrefix
        self.template = template
        self.folder = folder
    }
}
