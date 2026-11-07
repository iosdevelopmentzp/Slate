import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct BareURLTests {
    private func links(_ markdown: String) -> [String] {
        let text = MarkdownReader.read(markdown)
        var found: [String] = []
        text.enumerateAttribute(.slateHref, in: NSRange(location: 0, length: text.length)) { value, range, _ in
            guard let href = value as? String else { return }
            found.append("\((text.string as NSString).substring(with: range))=\(href)")
        }
        return found
    }

    @Test func anAddressInTheTextIsALink() {
        #expect(links("see https://example.com/a?b=1 now\n") == ["https://example.com/a?b=1=https://example.com/a?b=1"])
    }

    @Test func punctuationAfterTheAddressStaysText() {
        #expect(links("Open https://example.com/a. Then (https://example.com/b), done\n") == [
            "https://example.com/a=https://example.com/a",
            "https://example.com/b=https://example.com/b",
        ])
        #expect(links("see https://example.com/wiki/A_(b) now\n") == ["https://example.com/wiki/A_(b)=https://example.com/wiki/A_(b)"])
    }

    @Test func codeAndLinksAreLeftAlone() {
        #expect(links("run `https://example.com` and [map](https://example.com/m)\n") == ["map=https://example.com/m"])
    }

    @Test func aBareAddressIsWrittenBackAsItWas() {
        let markdown = "see https://example.com/group/project/-/merge_requests/12 now\n"

        #expect(MarkdownWriter.write(MarkdownReader.read(markdown)) == markdown)
    }

    @Test func aLinkWithOtherTextKeepsItsBrackets() {
        let markdown = "see [https://example.com/a](https://example.com/b) and [map](https://example.com/m)\n"

        #expect(MarkdownWriter.write(MarkdownReader.read(markdown)) == markdown)
    }
}
