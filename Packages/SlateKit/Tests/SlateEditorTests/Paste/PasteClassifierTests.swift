import Foundation
import Testing
@testable import SlateEditor

@Suite struct PasteClassifierTests {
    private func kind(_ string: String) -> PasteKind {
        PasteClassifier.classify(PasteboardSnapshot(string: string))
    }

    @Test func filesWinOverText() {
        let url = URL(fileURLWithPath: "/tmp/a.pdf")

        #expect(PasteClassifier.classify(PasteboardSnapshot(fileURLs: [url], string: "a.pdf")) == .files([url]))
    }

    @Test func imageDataIsAnImage() {
        let data = Data([1, 2, 3])

        #expect(PasteClassifier.classify(PasteboardSnapshot(image: (data, "png"))) == .image(data, fileExtension: "png"))
    }

    @Test func aURLOnItsOwnIsAURL() {
        #expect(kind("  https://example.com/a?b=1\n") == .url("https://example.com/a?b=1"))
        #expect(kind("see https://example.com") == .text("see https://example.com", codeLanguage: nil))
        #expect(kind("ftp://example.com") == .text("ftp://example.com", codeLanguage: nil))
    }

    @Test func shortTextIsPlain() {
        #expect(kind("one\ntwo") == .text("one\ntwo", codeLanguage: nil))
    }

    @Test func proseIsPlain() {
        let prose = "First line of a letter.\nSecond line goes on.\nThird line ends it."

        #expect(kind(prose) == .text(prose, codeLanguage: nil))
    }

    @Test func swiftCodeIsDetected() {
        let code = "func load() {\n    let value = 1\n    print(value)\n}"

        #expect(kind(code) == .text(code, codeLanguage: "swift"))
    }

    @Test func objectiveCIsDetected() {
        let code = "@implementation Foo\n- (void)bar {\n    [self baz];\n}\n@end"

        #expect(kind(code) == .text(code, codeLanguage: "objc"))
    }

    @Test func jsonIsDetected() {
        let json = "{\n  \"a\": 1,\n  \"b\": [true]\n}"

        #expect(kind(json) == .text(json, codeLanguage: "json"))
    }

    @Test func crashLogIsDetected() {
        let crash = "Exception Type: EXC_BAD_ACCESS\nThread 0 Crashed:\n0   App   0x0000000100abc Foo + 12\n1   App   0x0000000100abd Bar + 4"

        #expect(kind(crash) == .text(crash, codeLanguage: "log"))
    }

    @Test func timestampedLogIsDetected() {
        let log = "2026-10-16 10:01:02.123 App[1:2] start\n2026-10-16 10:01:03.000 App[1:2] load\n2026-10-16 10:01:04.000 App[1:2] done"

        #expect(kind(log) == .text(log, codeLanguage: "log"))
    }

    @Test func diffIsDetected() {
        let diff = "--- a/x\n+++ b/x\n@@ -1 +1 @@\n-old\n+new"

        #expect(kind(diff) == .text(diff, codeLanguage: "diff"))
    }

    @Test func fenceUsesMoreBackticksThanTheText() {
        #expect(PasteClassifier.fence("a\n```\nb", language: "plain") == "````\na\n```\nb\n````")
        #expect(PasteClassifier.fence("let a = 1\n", language: "swift") == "```swift\nlet a = 1\n```")
    }
}
