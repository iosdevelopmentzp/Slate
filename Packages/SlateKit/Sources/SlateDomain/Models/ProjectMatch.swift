import Foundation

package struct ProjectMatch: Hashable, Sendable {
    package let space: Space
    package let repository: RepositoryInfo?

    package init(space: Space, repository: RepositoryInfo?) {
        self.space = space
        self.repository = repository
    }
}
