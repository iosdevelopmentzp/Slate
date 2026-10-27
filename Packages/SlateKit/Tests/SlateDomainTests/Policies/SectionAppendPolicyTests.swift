import Foundation
import Testing
@testable import SlateDomain

@Suite struct SectionAppendPolicyTests {
    @Test func appendsAtTheEndOfTheSection() {
        let body = "## Log\n\n- 09:00 first\n\n\n## Notes\n\ntext\n"

        #expect(SectionAppendPolicy.append("- 10:42 second", toSection: "log", in: body) == "## Log\n\n- 09:00 first\n- 10:42 second\n\n## Notes\n\ntext\n")
    }

    @Test func emptySectionGetsABlankLineAfterTheHeading() {
        let body = "## Log\n\n\n\n## Notes\n"

        #expect(SectionAppendPolicy.append("- 10:42 x", toSection: "Log", in: body) == "## Log\n\n- 10:42 x\n\n## Notes\n")
    }

    @Test func lastSectionEndsWithOneNewline() {
        #expect(SectionAppendPolicy.append("found it", toSection: "Findings", in: "# T\n\n## Findings\nold") == "# T\n\n## Findings\nold\n\nfound it\n")
    }

    @Test func textAfterAParagraphStartsANewParagraph() {
        let body = "## Backend\n\nQ3. Question\nAnswer:\n\n## Product\n"

        #expect(SectionAppendPolicy.append("![Q2](a.png)", toSection: "Backend", in: body) == "## Backend\n\nQ3. Question\nAnswer:\n\n![Q2](a.png)\n\n## Product\n")
    }

    @Test func aListItemAfterAMultiLineListItemContinuesTheList() {
        let body = "## Log\n\n- 09:00 first\n  more\n"

        #expect(SectionAppendPolicy.append("- 10:42 second", toSection: "Log", in: body) == "## Log\n\n- 09:00 first\n  more\n- 10:42 second\n")
    }

    @Test func aListItemAfterAParagraphStartsANewList() {
        #expect(SectionAppendPolicy.append("- c", toSection: "Plan", in: "## Plan\ntext\n") == "## Plan\ntext\n\n- c\n")
    }

    @Test func anImageAfterAListIsNotPartOfTheLastItem() {
        let body = "## Conflicts\n\n1. first\n2. second\n"

        #expect(SectionAppendPolicy.append("![c](a.png)", toSection: "Conflicts", in: body) == "## Conflicts\n\n1. first\n2. second\n\n![c](a.png)\n")
    }

    @Test func deeperHeadingsStayInsideTheSection() {
        let body = "## Plan\n- a\n### Detail\n- b\n## Next\n"

        #expect(SectionAppendPolicy.append("- c", toSection: "Plan", in: body) == "## Plan\n- a\n### Detail\n- b\n- c\n\n## Next\n")
    }

    @Test func missingSectionIsAddedAtTheEnd() {
        #expect(SectionAppendPolicy.append("x", toSection: "Findings", in: "text\n") == "text\n\n## Findings\n\nx\n")
        #expect(SectionAppendPolicy.append("x", toSection: "Findings", in: "") == "## Findings\n\nx\n")
    }

    @Test func headingsInsideCodeAreNotSections() {
        let body = "```\n## Log\n```\n"

        #expect(SectionAppendPolicy.append("x", toSection: "Log", in: body) == "```\n## Log\n```\n\n## Log\n\nx\n")
    }

    @Test func noSectionAppendsAParagraph() {
        #expect(SectionAppendPolicy.append("x", toSection: nil, in: "text\n\n") == "text\n\nx\n")
    }
}
