import Foundation

package struct RepositoryInfo: Hashable, Sendable {
    package let root: String
    package let mainRoot: String
    package let remote: String?
    package let branch: String?

    package init(root: String, mainRoot: String? = nil, remote: String? = nil, branch: String? = nil) {
        self.root = root
        self.mainRoot = mainRoot ?? root
        self.remote = remote
        self.branch = branch
    }
}
