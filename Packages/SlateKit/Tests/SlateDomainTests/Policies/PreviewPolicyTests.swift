import Testing
@testable import SlateDomain

@Suite struct PreviewPolicyTests {
    @Test func stripsMarkdownMarks() {
        let body = """
        ## Context

        Leak after the **second** call in `ProfileViewModel`, see [the log](https://example.com) and [[Other note|that note]].

        - [ ] Break the _delegate_ cycle
        > Quote
        """

        #expect(PreviewPolicy.preview(of: body) == "Context Leak after the second call in ProfileViewModel, see the log and that note. Break the delegate cycle Quote")
    }

    @Test func skipsCodeFencesAndImages() {
        let body = "```swift\nlet x = 1\n```\n![](../_attachments/a.png)\nAfter"

        #expect(PreviewPolicy.preview(of: body) == "After")
    }

    @Test func dropsHighlightsAndColourTags() {
        let body = "A ==key point== and <mark style=\"background: #BBFABBA6;\">green</mark> <span style=\"color: #E5484D;\">red</span>, a == b"

        #expect(PreviewPolicy.preview(of: body) == "A key point and green red, a == b")
    }

    @Test func keepsSnakeCase() {
        #expect(PreviewPolicy.preview(of: "use snake_case_names") == "use snake_case_names")
    }

    @Test func cutsTo200Characters() {
        let body = String(repeating: "word ", count: 100)

        #expect(PreviewPolicy.preview(of: body).count <= 200)
    }

    @Test func emptyBodyGivesEmptyPreview() {
        #expect(PreviewPolicy.preview(of: "\n\n").isEmpty)
    }
}
