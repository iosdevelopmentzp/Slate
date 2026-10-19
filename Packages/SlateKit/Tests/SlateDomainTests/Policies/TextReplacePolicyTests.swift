import Foundation
import Testing
@testable import SlateDomain

@Suite struct TextReplacePolicyTests {
    @Test func replacesTheOnePlace() throws {
        #expect(try TextReplacePolicy.replacing("- [ ] tests", with: "- [x] tests", in: "- [ ] code\n- [ ] tests\n") == "- [ ] code\n- [x] tests\n")
    }

    @Test func emptyNewTextRemovesTheOldText() throws {
        #expect(try TextReplacePolicy.replacing("| 2 | b |\n", with: "", in: "| 1 | a |\n| 2 | b |\n") == "| 1 | a |\n")
    }

    @Test func missingOrRepeatedTextIsRefused() {
        #expect(throws: AgentError.textNotFound) { try TextReplacePolicy.replacing("x", with: "y", in: "abc") }
        #expect(throws: AgentError.textNotUnique(2)) { try TextReplacePolicy.replacing("- [ ]", with: "- [x]", in: "- [ ] a\n- [ ] b\n") }
        #expect(throws: AgentError.missingArgument("old")) { try TextReplacePolicy.replacing("", with: "y", in: "abc") }
    }
}
