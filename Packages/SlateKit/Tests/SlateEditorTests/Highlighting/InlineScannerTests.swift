import Foundation
import Testing
@testable import SlateEditor

@Suite struct InlineScannerTests {
    private func kinds(_ line: String, patterns: [EditorLinkPattern] = []) -> [String: InlineSpan.Kind] {
        let ns = line as NSString
        var result: [String: InlineSpan.Kind] = [:]
        for span in InlineScanner(patterns: CompiledLinkPattern.compile(patterns)).spans(in: line) where span.kind != .mark {
            result[ns.substring(with: span.range)] = span.kind
        }
        return result
    }

    @Test func emphasisAndCode() {
        let result = kinds("**bold** *it* `code` ~~gone~~")

        #expect(result["**bold**"] == .strong)
        #expect(result["*it*"] == .emphasis)
        #expect(result["code"] == .code)
        #expect(result["~~gone~~"] == .strike)
    }

    @Test func codeHidesMarksInside() {
        let result = kinds("`**not bold**`")

        #expect(result["**not bold**"] == .code)
        #expect(result.count == 1)
    }

    @Test func links() {
        let result = kinds("[site](https://example.com) and [[Other note|alias]] and https://example.org/a_b_c.")

        #expect(result["site"] == .link("https://example.com"))
        #expect(result["Other note|alias"] == .wikilink("Other note"))
        #expect(result["https://example.org/a_b_c"] == .url("https://example.org/a_b_c"))
        #expect(result["_b_"] == nil)
    }

    @Test func tags() {
        let result = kinds("a #audio/engine tag, not a#b or #123")

        #expect(result["#audio/engine"] == .tag("audio/engine"))
        #expect(result["#123"] == nil)
        #expect(result["#b"] == nil)
    }

    @Test func patterns() {
        let pattern = EditorLinkPattern(id: "ticket", regex: #"\b([A-Z][A-Z0-9]+-\d+)\b"#)
        let result = kinds("fix ABC-123 now", patterns: [pattern])

        #expect(result["ABC-123"] == .pattern(id: "ticket", match: "ABC-123"))
    }
}
