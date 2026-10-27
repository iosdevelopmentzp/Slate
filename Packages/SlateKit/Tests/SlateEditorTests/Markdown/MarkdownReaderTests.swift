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
}
