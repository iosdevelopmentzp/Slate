import Foundation

package struct IndexedNote: Hashable, Sendable {
    package var summary: NoteSummary
    package var state: IndexedFileState
    package var body: String
    package var aliases: [String]
    package var links: [IndexedLink]
    package var todos: [TodoItem]
    package var attachments: [String]
    package var hasCode: Bool
    package var hasImage: Bool
    package var hasLink: Bool

    package init(
        summary: NoteSummary,
        state: IndexedFileState,
        body: String = "",
        aliases: [String] = [],
        links: [IndexedLink] = [],
        todos: [TodoItem] = [],
        attachments: [String] = [],
        hasCode: Bool = false,
        hasImage: Bool = false,
        hasLink: Bool = false
    ) {
        self.summary = summary
        self.state = state
        self.body = body
        self.aliases = aliases
        self.links = links
        self.todos = todos
        self.attachments = attachments
        self.hasCode = hasCode
        self.hasImage = hasImage
        self.hasLink = hasLink
    }
}
