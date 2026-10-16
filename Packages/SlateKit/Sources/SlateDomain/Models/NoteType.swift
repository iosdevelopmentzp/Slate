import Foundation

package struct NoteType: Identifiable, Hashable, Sendable {
    package static let defaultName = "note"

    package let name: String
    package var title: String
    package var icon: String
    package var defaultSpace: SpaceName?
    package var fields: [String]
    package var titlePattern: String?
    package var branchPattern: String?
    package var statuses: [String]
    package var doneStatuses: [String]

    package var id: String {
        name
    }

    package var hasStatus: Bool {
        fields.contains("status")
    }

    package init(
        name: String,
        title: String,
        icon: String,
        defaultSpace: SpaceName? = nil,
        fields: [String] = [],
        titlePattern: String? = nil,
        branchPattern: String? = nil,
        statuses: [String] = [],
        doneStatuses: [String] = []
    ) {
        self.name = name
        self.title = title
        self.icon = icon
        self.defaultSpace = defaultSpace
        self.fields = fields
        self.titlePattern = titlePattern
        self.branchPattern = branchPattern
        self.statuses = statuses
        self.doneStatuses = doneStatuses
    }
}
