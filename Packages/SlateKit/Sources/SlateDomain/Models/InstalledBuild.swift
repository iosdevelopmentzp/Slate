import Foundation

package struct InstalledBuild: Hashable, Sendable {
    package var commit: String
    package var branch: String
    package var source: String

    package init(commit: String, branch: String, source: String) {
        self.commit = commit
        self.branch = branch
        self.source = source
    }

    package var shortCommit: String {
        String(commit.prefix(7))
    }
}
