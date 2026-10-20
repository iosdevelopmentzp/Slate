import Foundation
import Testing
@testable import SlateEditor

@MainActor
@Suite struct InlineWriterTests {

    private func styles(_ markdown: String) -> [(String, InlineStyle)] {
        let text = MarkdownReader.read(markdown)
        var result: [(String, InlineStyle)] = []
        text.enumerateAttribute(.slateInline, in: NSRange(location: 0, length: text.length)) { value, range, _ in
            result.append(((text.string as NSString).substring(with: range), InlineStyle(rawValue: value as? Int ?? 0)))
        }
        return result
    }

    private func styled(_ text: String, _ style: InlineStyle) -> NSAttributedString {
        var attributes = BlockAttributes().attributes
        attributes[.slateInline] = style.rawValue
        return NSAttributedString(string: text, attributes: attributes)
    }

    @Test func yellowIsWrittenWithEqualSignsAndOthersWithTags() {
        var yellow = InlineStyle()
        yellow.highlight = .yellow
        var blue = InlineStyle.bold
        blue.textColor = .blue
        let text = NSMutableAttributedString(attributedString: styled("a", yellow))
        text.append(styled(" b", blue))

        #expect(MarkdownWriter.write(text) == "==a== <span style=\"color: #0090FF;\">**b**</span>\n")
    }

    @Test func spacesMoveOutOfAHighlight() {
        var yellow = InlineStyle()
        yellow.highlight = .yellow
        let text = NSMutableAttributedString(attributedString: styled("a", []))
        text.append(styled(" b ", yellow))
        text.append(styled("c", []))

        #expect(MarkdownWriter.write(text) == "a ==b== c\n")
    }

    @Test func plainEqualSignsNextToAHighlightAreEscaped() {
        var yellow = InlineStyle()
        yellow.highlight = .yellow
        let text = NSMutableAttributedString(attributedString: styled("x=", []))
        text.append(styled("=y", yellow))
        let written = MarkdownWriter.write(text)

        #expect(written == "x\\===\\=y==\n")
        #expect(styles(written).map(\.0) == ["x=", "=y"])
    }
}
