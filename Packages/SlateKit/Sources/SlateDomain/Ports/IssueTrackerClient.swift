import Foundation

package protocol IssueTrackerClient: Sendable {
    func issue(_ key: String) async throws -> IssueDetails
    func currentUser() async throws -> String
}
