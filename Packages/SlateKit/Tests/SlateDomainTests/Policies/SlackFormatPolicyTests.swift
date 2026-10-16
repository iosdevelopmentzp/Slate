import Foundation
import Testing
@testable import SlateDomain

@Suite struct SlackFormatPolicyTests {
    @Test func boldItalicStrikeAndLinks() {
        #expect(SlackFormatPolicy.format("**bold** and *it* and ~~gone~~ [site](https://example.com)") == "*bold* and _it_ and ~gone~ <https://example.com|site>")
    }

    @Test func listsBecomeBulletsAndBoxes() {
        #expect(SlackFormatPolicy.format("- one\n  - two\n- [ ] open\n- [x] done") == "• one\n  • two\n☐ open\n☑︎ done")
    }

    @Test func headingsAreBoldAndCodeStays() {
        #expect(SlackFormatPolicy.format("## Plan\n```swift\nlet a = **b**\n```\n`**x**`") == "*Plan*\n```\nlet a = **b**\n```\n`**x**`")
    }

    @Test func wikilinksBecomeText() {
        #expect(SlackFormatPolicy.format("See [[Plan]] and [[Other|that one]]") == "See Plan and that one")
    }
}
