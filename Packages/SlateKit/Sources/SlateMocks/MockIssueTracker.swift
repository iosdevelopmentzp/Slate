import Foundation
import SlateDomain

struct MockIssueTracker: IssueTrackerClient {
    func issue(_ key: String) async throws -> IssueDetails {
        IssueDetails(key: key, summary: "Profile screen leaks memory", status: "In Progress", assignee: "Sam Example")
    }

    func currentUser() async throws -> String {
        "Sam Example"
    }
}
