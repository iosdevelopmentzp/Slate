import Foundation
import Testing
@testable import SlateDomain

@Suite struct SearchHighlightPolicyTests {
    @Test func rangesMatchWordStartsCaseInsensitive() {
        let text = "Retain cycle in the engine; retained."

        #expect(SearchHighlightPolicy.ranges(of: ["retain"], in: text) == [NSRange(location: 0, length: 6), NSRange(location: 28, length: 6)])
        #expect(SearchHighlightPolicy.ranges(of: ["tain"], in: text).isEmpty)
    }

    @Test func titleScorePrefersAPrefix() {
        #expect(SearchHighlightPolicy.titleScore("Retain cycle notes", words: ["retain", "cycle"]) == 2)
        #expect(SearchHighlightPolicy.titleScore("Notes on retain cycle", words: ["retain", "cycle"]) == 1)
        #expect(SearchHighlightPolicy.titleScore("Other", words: ["retain"]) == 0)
    }
}
