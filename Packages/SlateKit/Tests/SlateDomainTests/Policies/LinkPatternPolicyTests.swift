import Foundation
import Testing
@testable import SlateDomain

@Suite struct LinkPatternPolicyTests {
    private let patterns = LinkPatternPolicy.defaults(for: TrackerSettings(trackerBaseURL: "https://example.atlassian.net/", gitHostBaseURL: "https://gitlab.example.com", gitProjectPath: "/group/project/"))

    @Test func defaultsComeFromTheSettings() {
        #expect(patterns.map(\.id) == ["jira", "gitlab-mr", "gitlab-issue"])
        #expect(patterns[0].url == "https://example.atlassian.net/browse/$1")
        #expect(patterns[1].url == "https://gitlab.example.com/group/project/-/merge_requests/$1")
        #expect(LinkPatternPolicy.defaults(for: TrackerSettings()).isEmpty)
    }

    @Test func matchesExpandTheGroups() {
        let matches = LinkPatternPolicy.matches(in: "Fix ABC-2324 in !1234, see #12", patterns: patterns)

        #expect(matches.map(\.label) == ["ABC-2324", "!1234", "#12"])
        #expect(matches[0].url == "https://example.atlassian.net/browse/ABC-2324")
        #expect(matches[2].url == "https://gitlab.example.com/group/project/-/issues/12")
    }

    @Test func urlForAMatch() {
        #expect(LinkPatternPolicy.url(for: "gitlab-mr", match: "!7", patterns: patterns) == "https://gitlab.example.com/group/project/-/merge_requests/7")
        #expect(LinkPatternPolicy.url(for: "none", match: "!7", patterns: patterns) == nil)
    }

    @Test func shortFormOfAKnownURL() {
        #expect(LinkPatternPolicy.shortForm(for: "https://example.atlassian.net/browse/ABC-2324", patterns: patterns) == "ABC-2324")
        #expect(LinkPatternPolicy.shortForm(for: "https://gitlab.example.com/group/project/-/merge_requests/1234/diffs?x=1", patterns: patterns) == nil)
        #expect(LinkPatternPolicy.shortForm(for: "https://gitlab.example.com/group/project/-/merge_requests/1234", patterns: patterns) == "!1234")
        #expect(LinkPatternPolicy.shortForm(for: "https://example.com/other", patterns: patterns) == nil)
    }

    @Test func badRegexIsSkipped() {
        let broken = [LinkPattern(id: "x", regex: "(", url: "$1", label: "$1")]

        #expect(LinkPatternPolicy.matches(in: "(", patterns: broken).isEmpty)
    }
}
