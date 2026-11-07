import Testing
@testable import SlateEditor

@Suite struct SlackMarkupTests {
    @Test func inlineStylesUseSlackMarks() {
        #expect(SlackMarkup.render("## Plan\n\n**a** *b* ~~c~~ `d`\n") == "*Plan*\n\n*a* _b_ ~c~ `d`")
    }

    @Test func listsUseBulletsAndIndent() {
        let markdown = "- one\n    - inner\n\n3. three\n4. four\n\n- [x] done\n"

        #expect(SlackMarkup.render(markdown) == "• one\n    • inner\n\n3. three\n4. four\n\n• ☑ done")
    }

    @Test func linksShowTheAddressAfterTheLabel() {
        #expect(SlackMarkup.render("[MR](https://gitlab.example.com/a/-/merge_requests/1)\n") == "MR (https://gitlab.example.com/a/-/merge_requests/1)")
    }

    @Test func quotesAndCode() {
        #expect(SlackMarkup.render("> a\n\n```swift\nlet x = 1\n```\n") == "> a\n\n```\nlet x = 1\n```")
    }

    @Test func tablesBecomeAlignedText() {
        let markdown = "| Name | Size |\n| --- | --- |\n| long name | 1 |\n"

        #expect(SlackMarkup.render(markdown) == "```\nName       Size\n---------  ----\nlong name  1\n```")
    }
}
