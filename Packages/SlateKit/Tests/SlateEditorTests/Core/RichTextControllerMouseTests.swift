import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerMouseTests {
    private func imageRect(_ harness: EditorHarness, at index: Int) throws -> CGRect {
        let window = try #require(harness.textView.window)
        let screen = harness.textView.firstRect(forCharacterRange: NSRange(location: index, length: 1), actualRange: nil)
        return harness.textView.convert(window.convertFromScreen(screen), from: nil)
    }

    @Test func theImageMenuOffersSaveToDownloads() throws {
        let picture = try TestPicture()
        let url = picture.url
        let harness = EditorHarness(markdown: "Intro\n\n![](a.png)\n", resolveImage: { _ in url })
        var actions: [AttachmentAction] = []
        harness.controller.handlers.attachment = { path, action in if path == "a.png" { actions.append(action) } }

        let menu = try #require(harness.controller.imageMenu(at: 6))
        let save = try #require(menu.items.last)
        harness.textView.slateImageAction(save)

        #expect(menu.items.map(\.title) == ["Quick Look", "Open", "Show in Finder", "Copy Image", "Save to Downloads"])
        #expect(actions == [.saveToDownloads])
    }

    @Test func hoverOnAnImageShowsTheSaveButton() throws {
        let picture = try TestPicture(size: CGSize(width: 200, height: 120))
        let url = picture.url
        let harness = EditorHarness(markdown: "Intro\n\n![](a.png)\n", resolveImage: { _ in url })
        var actions: [AttachmentAction] = []
        harness.controller.handlers.attachment = { path, action in if path == "a.png" { actions.append(action) } }
        let rect = try imageRect(harness, at: 6)

        harness.controller.hoverImage(at: CGPoint(x: rect.midX, y: rect.midY))
        let button = harness.controller.imageButton
        button.performClick(nil)

        #expect(button.isHidden == false)
        #expect(button.superview === harness.textView)
        #expect(rect.contains(button.frame))
        #expect(actions == [.saveToDownloads])
    }

    @Test func theSaveButtonHidesOffTheImageAndAfterAnEdit() throws {
        let picture = try TestPicture(size: CGSize(width: 200, height: 120))
        let url = picture.url
        let harness = EditorHarness(markdown: "Intro\n\n![](a.png)\n", resolveImage: { _ in url })
        let rect = try imageRect(harness, at: 6)
        let button = harness.controller.imageButton

        harness.controller.hoverImage(at: CGPoint(x: rect.midX, y: rect.midY))
        harness.controller.hoverImage(at: nil)
        #expect(button.isHidden)

        harness.controller.hoverImage(at: CGPoint(x: rect.midX, y: rect.midY))
        harness.select(5)
        harness.type("!")
        #expect(button.isHidden)
    }

    @Test func aSmallImageGetsNoSaveButton() throws {
        let picture = try TestPicture(size: CGSize(width: 40, height: 20))
        let url = picture.url
        let harness = EditorHarness(markdown: "Intro\n\n![](a.png)\n", resolveImage: { _ in url })
        let rect = try imageRect(harness, at: 6)

        harness.controller.hoverImage(at: CGPoint(x: rect.midX, y: rect.midY))

        #expect(harness.controller.imageButton.isHidden)
    }
}
