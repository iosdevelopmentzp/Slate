import Foundation
import Testing
@testable import SlateEditor

@MainActor
@Suite struct MarkdownWriterTests {
    private static let words = ["plain", "a_b", "*", "_x_", "`tick`", "[box]", "#tag", "1.", "-", "&amp;", "C:\\path", "\\*", "<b>", "a>b", "~x~", "!", "|", "**", "end.", "(paren)", "snake_case", "x*y", "100%", "e-mail", "[[Note]]", "+1", "==", "a=b", "=", "x==y"]
    private static let kinds: [BlockKind] = [.title, .heading, .subheading, .body, .body, .body, .quote, .bullet, .numbered, .checklist, .monospaced]

    struct Generator {
        var state: UInt64

        mutating func next(_ bound: Int) -> Int {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Int((state >> 33) % UInt64(bound))
        }
    }

    static func randomDocument(seed: UInt64) -> NSAttributedString {
        var random = Generator(state: seed)
        let result = NSMutableAttributedString()
        for paragraph in 0..<(3 + random.next(6)) {
            let kind = kinds[random.next(kinds.count)]
            var block = BlockAttributes(kind: kind, isDone: kind == .checklist && random.next(2) == 0, group: kind == .quote || kind.isList ? 1 : 0)
            let previous = result.length == 0 ? BlockAttributes() : BlockAttributes.of(result, paragraphAt: result.length - 1)
            if kind.isList, previous.kind.isList { block.indent = min(random.next(previous.indent + 2), RichText.maxIndent) }
            let text = NSMutableAttributedString()
            for index in 0..<(1 + random.next(6)) {
                if index > 0 { text.append(NSAttributedString(string: " ")) }
                let word = words[random.next(words.count)]
                var attributes: [NSAttributedString.Key: Any] = [:]
                if kind != .monospaced {
                    var style = InlineStyle(rawValue: random.next(16))
                    style.highlight = HighlightColor(rawValue: random.next(8))
                    style.textColor = TextColor(rawValue: random.next(8))
                    if style.isEmpty == false { attributes[.slateInline] = style.rawValue }
                    if random.next(8) == 0 { attributes[.slateHref] = "https://example.com/\(word.count)" }
                }
                text.append(NSAttributedString(string: word, attributes: attributes))
            }
            if paragraph > 0 { result.append(NSAttributedString(string: "\n", attributes: BlockAttributes.of(result, paragraphAt: result.length - 1).attributes)) }
            text.addAttributes(block.attributes, range: NSRange(location: 0, length: text.length))
            result.append(text)
        }
        return result
    }

    struct Visible: Equatable {
        let kind: BlockKind
        let indent: Int
        let isDone: Bool
        let cells: [String]
    }

    static func visible(_ text: NSAttributedString) -> [Visible] {
        MarkdownWriter.paragraphs(of: text).map { paragraph in
            let isCode = paragraph.block.kind == .monospaced
            let cells = InlineCell.cells(of: paragraph.text).filter { $0.character.isWhitespace == false }.map { cell in
                "\(cell.character)|\(isCode ? 0 : cell.style.subtracting(.code).rawValue)|\(cell.isCode && isCode == false)|\(cell.href ?? "")"
            }
            return Visible(kind: paragraph.block.kind, indent: paragraph.block.indent, isDone: paragraph.block.isDone, cells: cells)
        }
    }

    @Test(arguments: 0..<300)
    func randomDocumentsSurviveAWriteAndARead(seed: Int) {
        let document = Self.randomDocument(seed: UInt64(seed) + 1)
        let written = MarkdownWriter.write(document)
        let read = MarkdownReader.read(written)

        let got = Self.visible(read), want = Self.visible(document)
        if got != want {
            let index = Array(zip(got, want)).firstIndex { $0.0 != $0.1 } ?? min(got.count, want.count)
            let g = index < got.count ? got[index].cells.joined(separator: " ") : "none"
            let w = index < want.count ? want[index].cells.joined(separator: " ") : "none"
            Issue.record("seed \(seed) counts \(got.count) \(want.count) kinds \(got.map(\.kind.rawValue)) vs \(want.map(\.kind.rawValue)) paragraph \(index)\nwritten: \(written)\nwant \(w)\ngot  \(g)")
        }
        #expect(MarkdownWriter.write(read) == written, "seed \(seed) is not stable")
    }

    @Test func numberedListsAreRenumbered() {
        let text = MarkdownReader.read("3. a\n7. b\n")

        #expect(MarkdownWriter.write(text) == "1. a\n2. b\n")
    }

    @Test func emptyParagraphsAndItemsAreDropped() {
        let text = MarkdownReader.read("a\n\n- b\n")
        let mutable = NSMutableAttributedString(attributedString: text)
        mutable.insert(NSAttributedString(string: "\n", attributes: BlockAttributes().attributes), at: 1)

        #expect(MarkdownWriter.write(mutable) == "a\n\n- b\n")
    }

    @Test func emptyDocumentIsEmpty() {
        #expect(MarkdownWriter.write(NSAttributedString()) == "")
        #expect(MarkdownReader.read("").length == 0)
    }

    @Test func spacesMoveOutOfBold() {
        let text = NSAttributedString(string: "a bold b", attributes: [.slateBlock: "body"])
        let styled = NSMutableAttributedString(attributedString: text)
        styled.addAttribute(.slateInline, value: InlineStyle.bold.rawValue, range: NSRange(location: 1, length: 6))

        #expect(MarkdownWriter.write(styled) == "a **bold** b\n")
    }

    @Test func codeSpansPickALongerFence() {
        #expect(InlineWriter.codeSpan("a`b") == "``a`b``")
        #expect(InlineWriter.codeSpan("`x") == "`` `x ``")
    }

    @Test func fenceGrowsPastBackticksInTheCode() {
        #expect(MarkdownWriter.fence("```\u{2028}x", language: nil) == "````\n```\nx\n````")
    }

    @Test func destinationsWithSpacesUseAngleBrackets() {
        #expect(InlineWriter.destination("../_attachments/my file.png") == "<../_attachments/my file.png>")
        #expect(InlineWriter.destination("https://example.com") == "https://example.com")
    }
}
