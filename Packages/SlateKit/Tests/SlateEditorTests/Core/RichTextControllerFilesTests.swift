import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerFilesTests {
    private let markdown = "Intro\n\n[CallPrompt.swift](../_attachments/a.swift)\n\nAfter\n"

    @Test func theFileMenuOpensShowsInFinderAndRemoves() throws {
        let harness = EditorHarness(markdown: markdown)
        var actions: [AttachmentAction] = []
        harness.controller.handlers.attachment = { path, action in if path == "../_attachments/a.swift" { actions.append(action) } }

        let menu = try #require(harness.controller.fileMenu(at: 6))
        for title in ["Open", "Show in Finder"] {
            harness.textView.slateImageAction(try #require(menu.items.first { $0.title == title }))
        }

        #expect(menu.items.map(\.title) == ["Open", "Quick Look", "Show in Finder", "Save to Downloads", "", "Remove"])
        #expect(actions == [.open, .reveal])
    }

    @Test func doubleClickOnTheCardOpensTheFile() throws {
        let harness = EditorHarness(markdown: markdown)
        var actions: [AttachmentAction] = []
        harness.controller.handlers.attachment = { _, action in actions.append(action) }
        let screen = harness.textView.firstRect(forCharacterRange: NSRange(location: 6, length: 1), actualRange: nil)
        let rect = harness.window.convertFromScreen(screen)
        let event = try #require(NSEvent.mouseEvent(with: .leftMouseDown, location: CGPoint(x: rect.midX, y: rect.midY), modifierFlags: [], timestamp: 0, windowNumber: harness.window.windowNumber, context: nil, eventNumber: 1, clickCount: 2, pressure: 1))

        #expect(harness.controller.handleMouseDown(event))
        #expect(actions == [.open])
    }

    @Test func removeTakesTheFileOutAndUndoBringsItBack() throws {
        let harness = EditorHarness(markdown: markdown)
        let remove = try #require(harness.controller.fileMenu(at: 6)?.items.first { $0.title == "Remove" })

        harness.textView.slateRemoveImage(remove)

        #expect(harness.markdown == "Intro\n\nAfter\n")
        harness.controller.undoEdit()
        #expect(harness.markdown == markdown)
    }

    @Test func theCardIsDrawnWithTheFileName() throws {
        let harness = EditorHarness(markdown: markdown)

        let card = try #require(harness.controller.storage.attribute(.attachment, at: 6, effectiveRange: nil) as? FileAttachment)

        #expect(card.name == "CallPrompt.swift")
        #expect(card.path == "../_attachments/a.swift")
    }
}
