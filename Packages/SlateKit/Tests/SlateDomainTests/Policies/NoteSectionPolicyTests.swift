import Foundation
import Testing
@testable import SlateDomain

@Suite struct NoteSectionPolicyTests {
    private let body = "## Status\n\n| Step | State |\n|---|---|\n| 1 | todo |\n\n## Plan\n- [ ] a\n### Detail\n- b\n## Log\n\n- old\n"

    @Test func textIsTheSectionWithItsSubSections() {
        #expect(NoteSectionPolicy.text(of: "plan", in: body) == "- [ ] a\n### Detail\n- b")
        #expect(NoteSectionPolicy.text(of: "Status", in: body) == "| Step | State |\n|---|---|\n| 1 | todo |")
        #expect(NoteSectionPolicy.text(of: "Missing", in: body) == nil)
    }

    @Test func headingsListEveryHeadingLine() {
        #expect(NoteSectionPolicy.headings(in: body) == ["## Status", "## Plan", "### Detail", "## Log"])
    }

    @Test func replacingKeepsTheHeadingAndTheOtherSections() {
        let result = NoteSectionPolicy.replacing("Plan", with: "- [x] a", in: body)

        #expect(result == "## Status\n\n| Step | State |\n|---|---|\n| 1 | todo |\n\n## Plan\n\n- [x] a\n\n## Log\n\n- old\n")
    }

    @Test func replacingTheLastSectionEndsWithOneNewline() {
        #expect(NoteSectionPolicy.replacing("Log", with: "- new\n\n", in: body).hasSuffix("## Log\n\n- new\n"))
    }

    @Test func replacingAMissingSectionAddsItAtTheEnd() {
        #expect(NoteSectionPolicy.replacing("Findings", with: "x", in: "text\n") == "text\n\n## Findings\n\nx\n")
    }

    @Test func prependPutsAListItemFirstInTheSameList() {
        let result = NoteSectionPolicy.prepend("- new", toSection: "Log", in: body)

        #expect(result.hasSuffix("## Log\n\n- new\n- old\n"))
    }

    @Test func prependOfAParagraphKeepsABlankLine() {
        #expect(NoteSectionPolicy.prepend("Intro", toSection: nil, in: "## Plan\n- a\n") == "Intro\n\n## Plan\n- a\n")
    }

    @Test func prependToAnEmptyOrMissingSectionAppends() {
        #expect(NoteSectionPolicy.prepend("- x", toSection: "Log", in: "## Log\n\n## Next\n") == "## Log\n\n- x\n\n## Next\n")
        #expect(NoteSectionPolicy.prepend("- x", toSection: "Log", in: "") == "## Log\n\n- x\n")
    }

    @Test func headingsInsideCodeAreNotSections() {
        let code = "## Plan\n```\n## Not a heading\n```\n- a\n"

        #expect(NoteSectionPolicy.text(of: "Plan", in: code) == "```\n## Not a heading\n```\n- a")
        #expect(NoteSectionPolicy.text(of: "Not a heading", in: code) == nil)
    }
}
