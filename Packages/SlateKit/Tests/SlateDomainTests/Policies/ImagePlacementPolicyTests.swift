import Foundation
import Testing
@testable import SlateDomain

@Suite struct ImagePlacementPolicyTests {
    private let image = "![](a.png)"

    @Test func anImageUnderANumberedItemIsIndentedToTheItemText() throws {
        let body = "1. First\n2. Second\n"

        #expect(try ImagePlacementPolicy.insert(image, after: "First", in: body) == "1. First\n\n   ![](a.png)\n\n2. Second\n")
    }

    @Test func anImageUnderANestedBulletGoesBeforeTheNextItem() throws {
        let body = "- a\n  - b\n    more of b\n  - c\n"

        #expect(try ImagePlacementPolicy.insert(image, after: "- b", in: body) == "- a\n  - b\n    more of b\n\n    ![](a.png)\n\n  - c\n")
    }

    @Test func anImageAfterAParagraphLineGoesAfterTheWholeParagraph() throws {
        let body = "Q2. Date?\nAnswer:\n\nQ3. Logout?\n"

        #expect(try ImagePlacementPolicy.insert(image, after: "Q2", in: body) == "Q2. Date?\nAnswer:\n\n![](a.png)\n\nQ3. Logout?\n")
    }

    @Test func anImageAfterTheLastLineEndsTheNote() throws {
        #expect(try ImagePlacementPolicy.insert(image, after: "end", in: "the end") == "the end\n\n![](a.png)")
    }

    @Test func textInCodeDoesNotCount() {
        #expect(throws: AgentError.textNotFound) { try ImagePlacementPolicy.insert(image, after: "x", in: "```\nx\n```\n") }
    }

    @Test func theTextMustBeThereOnce() {
        #expect(throws: AgentError.textNotUnique(2)) { try ImagePlacementPolicy.insert(image, after: "item", in: "- item 1\n- item 2\n") }
    }
}
