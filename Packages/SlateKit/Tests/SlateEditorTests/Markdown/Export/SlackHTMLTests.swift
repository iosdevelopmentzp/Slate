import Testing
@testable import SlateEditor

@Suite struct SlackHTMLTests {
    @Test func blocksBecomeTags() {
        let markdown = "## Plan\n\n- **a** & b\n- [x] c\n\n> q\n"

        #expect(SlackHTML.render(markdown) == "<p><b>Plan</b></p><ul><li><b>a</b> &amp; b</li><li>☑ c</li></ul><blockquote><p>q</p></blockquote>")
    }

    @Test func linksAndCode() {
        let markdown = "[t](https://example.com/?a=1&b=2) `x<y`\n\n```\nif a < b {}\n```\n"

        #expect(SlackHTML.render(markdown) == "<p><a href=\"https://example.com/?a=1&amp;b=2\">t</a> <code>x&lt;y</code></p><pre>if a &lt; b {}</pre>")
    }
}
