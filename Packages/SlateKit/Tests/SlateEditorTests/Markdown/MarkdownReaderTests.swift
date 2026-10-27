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
}
