import Foundation
import Testing
@testable import SlateDomain

@Suite struct TagPolicyTests {
    @Test func inlineTagsSkipHeadingsCodeAndNumbers() {
        let body = "# Heading\nA #audio note with #memory/leak and #123 and a#b.\n`#code`\n```\n#fenced\n```"

        #expect(TagPolicy.inlineTags(in: body) == ["audio", "memory/leak"])
    }

    @Test func mergedIsSortedLowercaseAndUnique() {
        #expect(TagPolicy.merged(header: ["Audio", "#ios"], body: "#audio #zeta") == ["audio", "ios", "zeta"])
    }

    @Test func prefixMatches() {
        #expect(TagPolicy.prefixMatches(["audio", "api", "ios"], prefix: "#a") == ["audio", "api"])
    }
}
