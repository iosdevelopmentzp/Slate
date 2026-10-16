import Foundation

package struct LinkPattern: Identifiable, Hashable, Sendable {
    package let id: String
    package var regex: String
    package var url: String
    package var label: String
    package var icon: String?

    package init(id: String, regex: String, url: String, label: String, icon: String? = nil) {
        self.id = id
        self.regex = regex
        self.url = url
        self.label = label
        self.icon = icon
    }
}
