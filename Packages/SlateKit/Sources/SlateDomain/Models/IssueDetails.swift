import Foundation

package struct IssueDetails: Hashable, Sendable {
    package let key: String
    package let summary: String
    package let status: String?
    package let assignee: String?

    package init(key: String, summary: String, status: String?, assignee: String?) {
        self.key = key
        self.summary = summary
        self.status = status
        self.assignee = assignee
    }
}
