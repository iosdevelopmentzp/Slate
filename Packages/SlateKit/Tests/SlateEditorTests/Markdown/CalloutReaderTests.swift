import Foundation
import Testing
@testable import SlateEditor

@Suite struct CalloutReaderTests {
    private func roundTrip(_ markdown: String) -> String {
        MarkdownWriter.write(MarkdownReader.read(markdown))
    }

    @Test func aCalloutKeepsItsMarkerAndText() {
        let markdown = "> [!NOTE]\n> Read this first.\n>\n> Then this.\n"

        #expect(roundTrip(markdown) == markdown)
    }

    @Test func aTitleStaysOnTheMarkerLine() {
        let markdown = "> [!warning]- Watch out\n> The build is slow.\n"

        #expect(roundTrip(markdown) == markdown)
    }

    @Test func theMarkerIsNotTextOnScreen() {
        let text = MarkdownReader.read("> [!QUESTION] Why?\n> Because.\n")
        let header = BlockAttributes.of(text, paragraphAt: 0)

        #expect(text.string.hasPrefix("Why?\nBecause."))
        #expect(header.callout == "QUESTION")
        #expect(header.isCalloutHeader)
        #expect(BlockAttributes.of(text, paragraphAt: 6).isCalloutHeader == false)
    }

    @Test func aPlainQuoteStaysAQuote() {
        let text = MarkdownReader.read("> [!] and more\n")

        #expect(BlockAttributes.of(text, paragraphAt: 0).callout == nil)
        #expect(roundTrip("> just a quote\n") == "> just a quote\n")
    }
}
