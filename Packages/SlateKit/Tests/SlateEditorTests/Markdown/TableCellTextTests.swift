import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct TableCellTextTests {
    @Test func plainAndStyledTextRoundTrip() throws {
        for markdown in ["plain", "**bold** and *italic*", "~~gone~~ `code`", "[site](https://example.com)", "a \\* star"] {
            let inline = try #require(TableCellText.inline(markdown))
            #expect(TableCellText.markdown(of: inline) == markdown)
        }
    }

    @Test func anImageBecomesOneCharacterWithItsPath() throws {
        let inline = try #require(TableCellText.inline("see ![shelf](../_attachments/a%20b.png) here"))

        #expect(inline.string == "see \u{FFFC} here")
        #expect(inline.attribute(.slateImagePath, at: 4, effectiveRange: nil) as? String == "../_attachments/a%20b.png")
        #expect(inline.attribute(.slateImageAlt, at: 4, effectiveRange: nil) as? String == "shelf")
        #expect(TableCellText.markdown(of: inline) == "see ![shelf](../_attachments/a%20b.png) here")
    }

    @Test func emptyCellsAreEmptyAndBlocksAreRefused() {
        #expect(TableCellText.inline("  ")?.length == 0)
        #expect(TableCellText.inline("- item") == nil)
        #expect(TableCellText.inline("> quote") == nil)
    }

    @Test func imagesAreAllowedOnlyInCells() {
        let text = MarkdownReader.read("Text ![](../_attachments/x.png) inline.\n")

        #expect(BlockAttributes(text.attributes(at: 0, effectiveRange: nil)).kind == .raw)
    }
}
