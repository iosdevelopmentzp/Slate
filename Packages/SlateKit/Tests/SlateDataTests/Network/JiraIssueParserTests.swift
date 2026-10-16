import Foundation
import SlateDomain
import Testing
@testable import SlateData

@Suite struct JiraIssueParserTests {
    @Test func issueFields() {
        let json = #"{"key":"ABC-1","fields":{"summary":"Fix it","status":{"name":"In Progress"},"assignee":{"displayName":"Sam"}}}"#

        #expect(JiraIssueParser.issue(from: Data(json.utf8)) == IssueDetails(key: "ABC-1", summary: "Fix it", status: "In Progress", assignee: "Sam"))
    }

    @Test func missingAssigneeAndBadJSON() {
        #expect(JiraIssueParser.issue(from: Data(#"{"key":"A-1","fields":{"summary":"x","assignee":null}}"#.utf8))?.assignee == nil)
        #expect(JiraIssueParser.issue(from: Data("nope".utf8)) == nil)
        #expect(JiraIssueParser.displayName(from: Data(#"{"displayName":"Sam"}"#.utf8)) == "Sam")
    }
}
