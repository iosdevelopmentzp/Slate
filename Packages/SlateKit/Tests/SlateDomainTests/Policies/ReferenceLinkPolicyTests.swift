import Foundation
import Testing
@testable import SlateDomain

@Suite struct ReferenceLinkPolicyTests {
    @Test func aTicketKeyGoesAtTheEndOfTheAddress() {
        #expect(ReferenceLinkPolicy.ticketURL("ABC-123", base: "https://example.atlassian.net/browse/")?.absoluteString == "https://example.atlassian.net/browse/ABC-123")
        #expect(ReferenceLinkPolicy.ticketURL("ABC-123", base: "https://example.atlassian.net/browse")?.absoluteString == "https://example.atlassian.net/browse/ABC-123")
        #expect(ReferenceLinkPolicy.ticketURL("ABC-123", base: "https://t.example.com/issue?id={key}")?.absoluteString == "https://t.example.com/issue?id=ABC-123")
        #expect(ReferenceLinkPolicy.ticketURL("ABC-123", base: " ") == nil)
    }

    @Test func remotesBecomeWebAddresses() {
        #expect(ReferenceLinkPolicy.webAddress(remote: "gitlab.example.com/group/app") == "https://gitlab.example.com/group/app")
        #expect(ReferenceLinkPolicy.webAddress(remote: "git@gitlab.example.com:group/app.git") == "https://gitlab.example.com/group/app")
        #expect(ReferenceLinkPolicy.webAddress(remote: "ssh://git@gitlab.example.com:2222/group/app.git") == "https://gitlab.example.com/group/app")
        #expect(ReferenceLinkPolicy.webAddress(remote: "https://gitlab.example.com/group/app/") == "https://gitlab.example.com/group/app")
        #expect(ReferenceLinkPolicy.webAddress(remote: "local") == nil)
    }

    @Test func mergeRequestsAndCommitsUseTheProjectAddress() {
        #expect(ReferenceLinkPolicy.mergeRequestURL(12, remote: "gitlab.example.com/group/app")?.absoluteString == "https://gitlab.example.com/group/app/-/merge_requests/12")
        #expect(ReferenceLinkPolicy.commitURL("a1b2c3d", remote: "gitlab.example.com/group/app")?.absoluteString == "https://gitlab.example.com/group/app/commit/a1b2c3d")
    }
}
