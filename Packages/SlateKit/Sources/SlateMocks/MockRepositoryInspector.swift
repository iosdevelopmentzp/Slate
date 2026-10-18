import Foundation
import SlateDomain

struct MockRepositoryInspector: RepositoryInspecting {
    func inspect(_ directory: URL) async -> RepositoryInfo? {
        RepositoryInfo(root: directory.path, remote: "git@gitlab.example.com:group/project.git", branch: "feature/ABC-123-short-title")
    }
}
