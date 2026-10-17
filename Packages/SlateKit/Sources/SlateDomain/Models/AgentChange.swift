import Foundation

package struct AgentChange: Hashable, Sendable, Codable {
    package var date: Date
    package var tool: String
    package var title: String
    package var path: VaultPath

    package init(date: Date, tool: String, title: String, path: VaultPath) {
        self.date = date
        self.tool = tool
        self.title = title
        self.path = path
    }
}
