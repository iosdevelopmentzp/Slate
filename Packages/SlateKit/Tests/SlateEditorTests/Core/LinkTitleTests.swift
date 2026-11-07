import Testing
@testable import SlateEditor

@Suite struct LinkTitleTests {

    @Test func aTicketAddressGivesTheTicket() {
        #expect(LinkTitle.short(for: "https://example.atlassian.net/browse/ABC-123") == "ABC-123")
        #expect(LinkTitle.short(for: "https://example.atlassian.net/jira/software/projects/ABC/boards/1?selectedIssue=ABC-77") == "ABC-77")
    }

    @Test func aMergeRequestGivesTheProjectAndNumber() {
        #expect(LinkTitle.short(for: "https://gitlab.example.com/group/ios-app/-/merge_requests/1234/diffs") == "ios-app !1234")
        #expect(LinkTitle.short(for: "https://gitlab.example.com/group/ios-app/-/issues/5") == "ios-app #5")
        #expect(LinkTitle.short(for: "https://gitlab.example.com/group/ios-app/-/commit/0123456789abcdef") == "ios-app@0123456")
    }

    @Test func aPullRequestGivesTheRepositoryAndNumber() {
        #expect(LinkTitle.short(for: "https://example.com/owner/tool/pull/42") == "tool #42")
        #expect(LinkTitle.short(for: "https://example.com/owner/tool/issues/7#issuecomment-1") == "tool #7")
    }

    @Test func aWikiPageAndADesignFileGiveTheirNames() {
        #expect(LinkTitle.short(for: "https://example.atlassian.net/wiki/spaces/ABC/pages/123456/Release+Plan+2026") == "Release Plan 2026")
        #expect(LinkTitle.short(for: "https://example.com/design/AbC123xyz/Profile-Screen?node-id=1-2") == "Profile Screen")
    }

    @Test func otherAddressesHaveNoShortName() {
        #expect(LinkTitle.short(for: "https://example.com/docs/start") == nil)
        #expect(LinkTitle.short(for: "mailto:me@example.com") == nil)
    }
}
