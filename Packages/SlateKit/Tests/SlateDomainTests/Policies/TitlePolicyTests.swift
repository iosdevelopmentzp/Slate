import Testing
@testable import SlateDomain

@Suite struct TitlePolicyTests {
    @Test func firstNonEmptyLineBecomesTheTitle() {
        #expect(TitlePolicy.title(fromBody: "\n\n## Engine delegate must be weak\nmore") == "Engine delegate must be weak")
    }

    @Test func listMarksAreRemoved() {
        #expect(TitlePolicy.title(fromBody: "- [ ] Buy milk") == "Buy milk")
    }

    @Test func emptyBodyHasNoTitle() {
        #expect(TitlePolicy.title(fromBody: "  \n\n") == nil)
    }
}
