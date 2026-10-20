import Foundation
import Testing
@testable import SlateEditor

@MainActor
@Suite struct InlineReaderTests {

    private func styles(_ markdown: String) -> [(String, InlineStyle)] {
        let text = MarkdownReader.read(markdown)
        var result: [(String, InlineStyle)] = []
        text.enumerateAttribute(.slateInline, in: NSRange(location: 0, length: text.length)) { value, range, _ in
            result.append(((text.string as NSString).substring(with: range), InlineStyle(rawValue: value as? Int ?? 0)))
        }
        return result
    }

    @Test func equalSignsMakeAYellowHighlight() {
        let parts = styles("a ==b c== d\n")

        #expect(parts.map(\.0) == ["a ", "b c", " d"])
        #expect(parts[1].1.highlight == .yellow)
        #expect(parts[0].1.highlight == nil)
    }

    @Test func equalSignsWithSpacesInsideStayText() {
        #expect(styles("a == b == c\n").map(\.0) == ["a == b == c"])
        #expect(styles("x === y\n").map(\.0) == ["x === y"])
        #expect(styles("a \\=\\=b== c\n").map(\.0) == ["a ==b== c"])
    }

    @Test func aHighlightCanHoldBoldAndCode() {
        let parts = styles("==a **b** `c`==\n")

        #expect(parts.map(\.0) == ["a ", "b", " ", "c"])
        #expect(parts.allSatisfy { $0.1.highlight == .yellow })
        #expect(parts[1].1.contains(.bold))
        #expect(parts[3].1.contains(.code))
    }

    @Test func markAndSpanTagsGiveTheirColours() {
        let parts = styles("<mark style=\"background: #BBFABBA6;\">g</mark> <span style=\"color: #e5484d\">r</span>\n")

        #expect(parts.map(\.0) == ["g", " ", "r"])
        #expect(parts[0].1.highlight == .green)
        #expect(parts[2].1.textColor == .red)
    }

    @Test func anUnknownColourKeepsTheParagraphAsItIs() {
        let source = "<mark style=\"background: #123456;\">x</mark>\n"
        let text = MarkdownReader.read(source)

        #expect(BlockAttributes.of(text, paragraphAt: 0).kind == .raw)
        #expect(MarkdownWriter.write(text) == source)
    }

    @Test func anUnclosedTagKeepsTheParagraphAsItIs() {
        let text = MarkdownReader.read("<span style=\"color: #E5484D;\">x\n")

        #expect(BlockAttributes.of(text, paragraphAt: 0).kind == .raw)
    }

    @Test func aWikilinkWithEqualSignsInItsLabelStaysALink() {
        let text = MarkdownReader.read("[[Note|a==b==c]]\n")

        #expect(text.attribute(.slateHref, at: 0, effectiveRange: nil) as? String == "wiki:Note")
        #expect(text.string == "a==b==c")
    }
}
