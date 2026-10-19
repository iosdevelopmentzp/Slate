import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerPasteCodeTests {
    private func pasteboard(_ text: String, html: String? = nil) -> NSPasteboard {
        let board = NSPasteboard(name: NSPasteboard.Name("slate.tests.\(UUID().uuidString)"))
        board.clearContents()
        if let html {
            board.setString(html, forType: .html)
        }
        board.setString(text, forType: .string)
        return board
    }

    @Test func pastedJSONBecomesACodeBlock() {
        let harness = EditorHarness(markdown: "Payload\n")
        harness.select(7)

        harness.controller.paste(from: pasteboard(#"{"a":1,"b":[true]}"#))

        #expect(harness.markdown == "Payload\n\n```json\n{\n  \"a\": 1,\n  \"b\": [\n    true\n  ]\n}\n```\n")
    }

    @Test func codeCopiedFromAWebPageBecomesACodeBlock() {
        let harness = EditorHarness(markdown: "")
        let code = "if ready {\n    start()\n}"

        harness.controller.paste(from: pasteboard(code, html: "<pre>if ready {<br>    start()<br>}</pre>"))

        #expect(harness.markdown == "```\nif ready {\n    start()\n}\n```\n")
    }

    @Test func pasteInsideACodeBlockKeepsOneBlock() {
        let harness = EditorHarness(markdown: "```\nlet a = 1\n```\n")
        harness.caret(after: "1")

        harness.controller.paste(from: pasteboard("\n{\n  \"b\": 2\n}"))

        #expect(harness.markdown == "```\nlet a = 1\n{\n  \"b\": 2\n}\n```\n")
    }

    @Test func proseStaysParagraphs() {
        let harness = EditorHarness(markdown: "")

        harness.controller.paste(from: pasteboard("First line.\nSecond line."))

        #expect(harness.markdown == "First line.\n\nSecond line.\n")
    }

    @Test func theCodeButtonTurnsACodeBlockBackIntoParagraphs() {
        let harness = EditorHarness(markdown: "```\none\ntwo\n```\n")
        harness.select(1)

        harness.controller.perform(.list(.monospaced))

        #expect(harness.markdown == "one\n\ntwo\n")
    }
}
