import Foundation

package struct SmartView: Identifiable, Hashable, Sendable {
    package let id: String
    package var title: String
    package var icon: String
    package var query: String

    package init(id: String, title: String, icon: String, query: String) {
        self.id = id
        self.title = title
        self.icon = icon
        self.query = query
    }

    package static let defaults: [SmartView] = [
        SmartView(id: "open-todos", title: "Open TODOs", icon: "checklist", query: "is:todo"),
        SmartView(id: "active-tasks", title: "Active tasks", icon: "bolt", query: "type:task status:active"),
        SmartView(id: "this-week", title: "Changed this week", icon: "clock", query: "after:-7d"),
        SmartView(id: "untagged", title: "Untagged", icon: "tag.slash", query: "-has:tag"),
        SmartView(id: "conflicts", title: "Conflicts", icon: "exclamationmark.triangle", query: "is:conflict"),
    ]
}
