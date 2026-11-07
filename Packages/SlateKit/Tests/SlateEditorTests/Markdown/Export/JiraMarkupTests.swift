import Testing
@testable import SlateEditor

@Suite struct JiraMarkupTests {
    @Test func headingsAndInlineStylesUseWikiMarks() {
        let markdown = "# Title\n\n## Plan\n\nSome **bold**, *italic*, ~~gone~~ and `code`.\n"

        #expect(JiraMarkup.render(markdown) == "h1. Title\n\nh2. Plan\n\nSome *bold*, _italic_, -gone- and {{code}}.")
    }

    @Test func listsNestWithRepeatedMarks() {
        let markdown = "- one\n    - inner\n- two\n\n1. first\n2. second\n"

        #expect(JiraMarkup.render(markdown) == "* one\n** inner\n* two\n\n# first\n# second")
    }

    @Test func checklistItemsShowBoxes() {
        #expect(JiraMarkup.render("- [ ] open\n- [x] done\n") == "* ☐ open\n* ☑ done")
    }

    @Test func linksUseLabelAndAddress() {
        let markdown = "See [the ticket](https://example.atlassian.net/browse/ABC-123) and https://example.com/a_b_c here.\n"

        #expect(JiraMarkup.render(markdown) == "See [the ticket|https://example.atlassian.net/browse/ABC-123] and https://example.com/a_b_c here.")
    }

    @Test func noteLinksBecomePlainNames() {
        #expect(JiraMarkup.render("See [[Login flow]] and [[Plan|the plan]].\n") == "See Login flow and the plan.")
    }

    @Test func codeBlocksKeepTheirLanguage() {
        let markdown = "```swift\nlet a = [1]\n```\n\n```log\nline\n```\n"

        #expect(JiraMarkup.render(markdown) == "{code:swift}\nlet a = [1]\n{code}\n\n{noformat}\nline\n{noformat}")
    }

    @Test func tablesUseDoubleBarsForTheHeader() {
        let markdown = "| Name | Size |\n| --- | --- |\n| a<br>b | |\n"

        #expect(JiraMarkup.render(markdown) == "||Name||Size||\n|a \\\\ b| |")
    }

    @Test func quotesAndDividers() {
        #expect(JiraMarkup.render("> said\n\n---\n") == "{quote}\nsaid\n{quote}\n\n----")
    }

    @Test func imagesUseTheFileNameAndWidth() {
        #expect(JiraMarkup.render("![shot|420](_attachments/Screen%20Shot.png)\n") == "!Screen Shot.png|width=420!")
    }

    @Test func wikiCharactersInTextAreEscaped() {
        #expect(JiraMarkup.render("a {b} [c] d!\n") == "a \\{b\\} \\[c\\] d\\!")
    }

    @Test func highlightMarksGoAndTextColourStays() {
        let markdown = "a ==b== <span style=\"color: #E5484D;\">c</span>\n"

        #expect(JiraMarkup.render(markdown) == "a b {color:red}c{color}")
    }
}
