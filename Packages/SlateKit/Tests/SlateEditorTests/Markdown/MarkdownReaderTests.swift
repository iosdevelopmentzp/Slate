import Foundation
import Testing
@testable import SlateEditor

@MainActor
@Suite struct MarkdownReaderTests {

    static func kinds(_ text: NSAttributedString) -> [BlockKind] {
        var kinds: [BlockKind] = []
        let string = text.string as NSString
        var location = 0
        while location < string.length {
            let range = string.paragraphRange(for: NSRange(location: location, length: 0))
            kinds.append(BlockAttributes(text.attributes(at: range.location, effectiveRange: nil)).kind)
            location = NSMaxRange(range)
        }
        return kinds
    }

    @Test func listsInsideAQuoteAreQuotedListItems() {
        let text = MarkdownReader.read("> **Known**\n> 1. Row 3\n> 2. Row 4\n>\n> - Q1\n\n- outside")
        let blocks = MarkdownWriter.paragraphs(of: text).map(\.block)

        #expect(Self.kinds(text) == [.quote, .numbered, .numbered, .bullet, .bullet])
        #expect(blocks.map(\.isQuoted) == [false, true, true, true, false])
        #expect(Set(blocks.prefix(4).map(\.group)).count == 1)
        #expect(MarkdownWriter.write(text) == "> **Known**\n>\n> 1. Row 3\n> 2. Row 4\n>\n> - Q1\n\n- outside\n")
    }

    @Test func aListInsideACalloutKeepsTheCallout() {
        let text = MarkdownReader.read("> [!WARNING] Check\n> - one\n> - two")
        let blocks = MarkdownWriter.paragraphs(of: text).map(\.block)

        #expect(Self.kinds(text) == [.quote, .bullet, .bullet])
        #expect(blocks.map(\.callout) == ["WARNING", "WARNING", "WARNING"])
        #expect(MarkdownWriter.write(text) == "> [!WARNING] Check\n> - one\n> - two\n")
    }

    @Test func aNumberedListKeepsItsFirstNumber() {
        let markdown = "> **Fix**\n>\n> 5. Row 9\n> 6. Row 10\n\n3. Three\n4. Four\n   1. nested\n"
        let text = MarkdownReader.read(markdown)

        #expect(MarkdownWriter.write(text) == markdown)
    }

    @Test func aCodeBlockInsideAQuoteStaysRaw() {
        let text = MarkdownReader.read("> text\n> ```\n> code\n> ```")

        #expect(Self.kinds(text) == [.raw])
    }

    @Test func anImageOnItsOwnLineInsideAParagraphIsAnImage() {
        let text = MarkdownReader.read("**Q3.** Question\nAnswer:\n![Q2 sheet](../_attachments/a.png)\nAfter")

        #expect(Self.kinds(text) == [.body, .image, .body])
        #expect(MarkdownWriter.write(text) == "**Q3.** Question\nAnswer:\n\n![Q2 sheet](../_attachments/a.png)\n\nAfter\n")
    }

    @Test func anImageInsideALineOfTextStaysRaw() {
        let text = MarkdownReader.read("Look at ![x](a.png) here\nnext")

        #expect(Self.kinds(text) == [.raw])
    }

    @Test func twoImageLinesInOneParagraphAreTwoImages() {
        let text = MarkdownReader.read("![a](a.png)\n![b](b.png)")

        #expect(Self.kinds(text) == [.image, .image])
    }

    @Test func aLogEntryWithSeveralLinesIsOneItem() {
        let text = MarkdownReader.read("- **2026-10-27 07:44** **Done:** read.\n  **Left:** review.\n- **2026-10-27 08:07** **Done:** added.")

        #expect(Self.kinds(text) == [.bullet, .bullet])
    }

    @Test func anImageUnderAListItemKeepsTheListAndComesBackTheSame() {
        let markdown = "1. First\n\n   ![shot](a.png)\n\n2. Second\n   - nested\n\n     ![](b.png)\n"
        let text = MarkdownReader.read(markdown)

        #expect(Self.kinds(text) == [.numbered, .image, .numbered, .bullet, .image])
        #expect(MarkdownWriter.write(text) == markdown)
    }

    @Test func anImageLineGluedToAListItemGoesUnderTheItem() {
        let text = MarkdownReader.read("- a\n- b\n  more\n![x](a.png)\n- c")

        #expect(Self.kinds(text) == [.bullet, .bullet, .image, .bullet])
        #expect(MarkdownWriter.write(text) == "- a\n- b\n  more\n\n  ![x](a.png)\n\n- c\n")
    }

    @Test func textAfterAnImageInAListItemStaysRaw() {
        let text = MarkdownReader.read("- a\n\n  ![x](a.png)\n\n  more text\n")

        #expect(Self.kinds(text) == [.raw])
    }

    @Test func aFileLinkOnItsOwnLineIsAFileCard() {
        let text = MarkdownReader.read("[CallPrompt.swift](../_attachments/20261116-101500-CallPrompt.swift)")
        let block = MarkdownWriter.paragraphs(of: text)[0].block

        #expect(Self.kinds(text) == [.file])
        #expect(block.filePath == "../_attachments/20261116-101500-CallPrompt.swift")
        #expect(block.fileName == "CallPrompt.swift")
    }

    @Test func twoFileLinesInOneParagraphAreTwoCards() {
        let text = MarkdownReader.read("Files:\n[a.swift](../_attachments/a.swift)\n[Spec 2.pdf](../_attachments/Spec%202.pdf)")

        #expect(Self.kinds(text) == [.body, .file, .file])
        #expect(MarkdownWriter.write(text) == "Files:\n\n[a.swift](../_attachments/a.swift)\n\n[Spec 2.pdf](../_attachments/Spec%202.pdf)\n")
    }

    @Test func aLargeFileLinkedInPlaceIsAFileCard() {
        let text = MarkdownReader.read("[movie.mov](file:///Users/me/movie.mov)")

        #expect(Self.kinds(text) == [.file])
    }

    @Test func otherLinksStayText() {
        let text = MarkdownReader.read("[site](https://example.com)\n\nSee [a.swift](../_attachments/a.swift) here\n\n[**bold**](../_attachments/a.swift)\n\n- [a.swift](../_attachments/a.swift)")

        #expect(Self.kinds(text) == [.body, .body, .body, .bullet])
    }
}
