import Foundation

package struct ProjectInfo: Hashable, Sendable {
    package let id: String
    package var repositories: [String]
    package var remote: String?

    package init(id: String = UUID().uuidString.lowercased(), repositories: [String] = [], remote: String? = nil) {
        self.id = id
        self.repositories = repositories
        self.remote = remote
    }
}
