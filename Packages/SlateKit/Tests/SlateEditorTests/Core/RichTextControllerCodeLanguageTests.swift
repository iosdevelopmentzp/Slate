import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerCodeLanguageTests {

    @Test func aSwiftBlockColoursItsKeywordsAndStrings() {
        let harness = EditorHarness(markdown: "```swift\nlet name = \"Slate\"\n```\n")
        let storage = harness.controller.storage

        let keyword = storage.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        let string = storage.attribute(.foregroundColor, at: 11, effectiveRange: nil) as? NSColor
        let plain = storage.attribute(.foregroundColor, at: 4, effectiveRange: nil) as? NSColor

        #expect(keyword == CodePalette.color(for: .keyword))
        #expect(string == CodePalette.color(for: .string))
        #expect(plain != CodePalette.color(for: .keyword))
    }

    @Test func aBlockWithoutALanguageStaysOneColour() {
        let harness = EditorHarness(markdown: "```\nlet name = 1\n```\n")
        let storage = harness.controller.storage
        var colours: [NSColor] = []
        storage.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: storage.length)) { value, _, _ in
            if let colour = value as? NSColor { colours.append(colour) }
        }

        #expect(colours.count == 1)
    }

    @Test func typingInABlockKeepsTheColours() {
        let harness = EditorHarness(markdown: "```swift\nlet a = 1\n```\n")
        harness.select(9)

        harness.type(" + 2")

        #expect(harness.markdown == "```swift\nlet a = 1 + 2\n```\n")
        #expect(harness.controller.storage.attribute(.foregroundColor, at: 12, effectiveRange: nil) as? NSColor == CodePalette.color(for: .number))
    }

    @Test func choosingALanguageWritesItIntoTheFence() {
        let harness = EditorHarness(markdown: "```\n{\"a\": 1}\n```\n")

        harness.controller.setCodeLanguage(at: 0, fence: "json")

        #expect(harness.markdown == "```json\n{\"a\": 1}\n```\n")
        #expect(harness.controller.storage.attribute(.foregroundColor, at: 6, effectiveRange: nil) as? NSColor == CodePalette.color(for: .number))
        harness.controller.setCodeLanguage(at: 0, fence: nil)
        #expect(harness.markdown == "```\n{\"a\": 1}\n```\n")
    }

    @Test func theLabelNamesTheLanguage() {
        #expect(CodeLanguage.label(for: "swift") == "Swift")
        #expect(CodeLanguage.label(for: "zsh") == "Shell")
        #expect(CodeLanguage.label(for: "python") == "python")
        #expect(CodeLanguage.label(for: nil) == "Plain text")
    }

    @Test func aClickOnTheLabelFindsTheBlock() throws {
        let harness = EditorHarness(markdown: "Intro\n\n```swift\nlet a = 1\n```\n")
        let layout = try #require(harness.textView.textLayoutManager)
        var label: CGPoint?
        layout.enumerateTextLayoutFragments(from: layout.documentRange.location, options: [.ensuresLayout]) { fragment in
            guard let rich = fragment as? RichLayoutFragment, rich.languageLabel != nil else { return true }
            let rect = rich.languageLabelRect.offsetBy(dx: rich.layoutFragmentFrame.minX, dy: rich.layoutFragmentFrame.minY)
            label = CGPoint(x: rect.midX + harness.textView.textContainerOrigin.x, y: rect.midY + harness.textView.textContainerOrigin.y)
            return false
        }
        let point = try #require(label)

        #expect(harness.controller.codeLanguageHit(at: point) == 6)
        #expect(harness.controller.codeLanguageHit(at: CGPoint(x: point.x - 300, y: point.y)) == nil)
    }

    @Test func piecesSplitARunAtTokenEdges() {
        let tokens = [CodeToken(range: NSRange(location: 2, length: 3), kind: .keyword)]

        let pieces = RichTextStyler.pieces(of: NSRange(location: 0, length: 8), tokens: tokens)

        #expect(pieces.map(\.0) == [NSRange(location: 0, length: 2), NSRange(location: 2, length: 3), NSRange(location: 5, length: 3)])
        #expect(pieces.map { $0.1 == nil } == [true, false, true])
    }
}
