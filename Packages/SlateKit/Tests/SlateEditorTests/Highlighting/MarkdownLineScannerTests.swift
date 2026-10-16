import Foundation
import Testing
@testable import SlateEditor

@Suite struct MarkdownLineScannerTests {
    @Test func headings() {
        #expect(MarkdownLineScanner.kind(of: "## Plan") == .heading(level: 2, markLength: 3))
        #expect(MarkdownLineScanner.kind(of: "#tag") == .paragraph)
        #expect(MarkdownLineScanner.kind(of: "####### seven") == .paragraph)
    }

    @Test func listItems() throws {
        guard case .listItem(let item) = MarkdownLineScanner.kind(of: "  - [x] done") else {
            Issue.record("not a list item")
            return
        }
        #expect(item.indent == 2)
        #expect(item.checkbox == ListItem.Checkbox(isChecked: true, range: NSRange(location: 4, length: 3)))
        #expect(item.contentStart == 8)
    }

    @Test func orderedItem() {
        guard case .listItem(let item) = MarkdownLineScanner.kind(of: "12) step") else {
            Issue.record("not a list item")
            return
        }
        #expect(item.marker == .ordered(number: 12, delimiter: ")"))
        #expect(item.contentStart == 4)
    }

    @Test func otherKinds() {
        #expect(MarkdownLineScanner.kind(of: "") == .blank)
        #expect(MarkdownLineScanner.kind(of: "> quote") == .quote(markLength: 2))
        #expect(MarkdownLineScanner.kind(of: "---") == .rule)
        #expect(MarkdownLineScanner.kind(of: "| a | b |") == .tableRow)
        #expect(MarkdownLineScanner.kind(of: "![](../_attachments/a%20b.png)") == .image(source: "../_attachments/a%20b.png", sourceRange: NSRange(location: 4, length: 25)))
        #expect(MarkdownLineScanner.kind(of: "-not a list") == .paragraph)
    }
}
