import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerCodeCopyTests {
    private let markdown = "Intro\n\n```swift\nlet a = 1\nprint(a)\n```\n\nAfter\n"

    private func point(of needle: String, in harness: EditorHarness) throws -> CGPoint {
        let window = try #require(harness.textView.window)
        let range = (harness.text as NSString).range(of: needle)
        let screen = harness.textView.firstRect(forCharacterRange: NSRange(location: range.location, length: 1), actualRange: nil)
        let rect = harness.textView.convert(window.convertFromScreen(screen), from: nil)
        return CGPoint(x: rect.midX, y: rect.midY)
    }

    @Test func hoverOnACodeBlockShowsTheCopyButton() throws {
        let harness = EditorHarness(markdown: markdown)

        harness.controller.hoverCode(at: try point(of: "print", in: harness))

        #expect(harness.controller.codeCopyButton.isHidden == false)
        #expect(harness.controller.codeCopyButton.location == 6)
    }

    @Test func hoverOnOtherTextHidesIt() throws {
        let harness = EditorHarness(markdown: markdown)

        harness.controller.hoverCode(at: try point(of: "print", in: harness))
        harness.controller.hoverCode(at: try point(of: "After", in: harness))

        #expect(harness.controller.codeCopyButton.isHidden)
    }

    @Test func copyPutsTheCodeWithLineBreaksOnTheClipboard() {
        let harness = EditorHarness(markdown: markdown)
        let board = NSPasteboard.withUniqueName()
        var notices: [String] = []
        harness.controller.handlers.notice = { notices.append($0) }

        harness.controller.copyCode(at: 6, to: board)

        #expect(board.string(forType: .string) == "let a = 1\nprint(a)")
        #expect(notices == ["Copied the code"])
    }
}
