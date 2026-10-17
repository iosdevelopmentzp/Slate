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
        let save = try #require(menu.items.first { $0.title == "Save to Downloads" })
        harness.textView.slateImageAction(save)

        #expect(menu.items.map(\.title) == ["Quick Look", "Open", "Show in Finder", "Copy Image", "Save to Downloads", "Size"])
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

    @Test func theSizeMenuWritesTheWidthIntoTheAltText() throws {
        let picture = try TestPicture(size: CGSize(width: 800, height: 400))
        let url = picture.url
        let harness = EditorHarness(markdown: "Intro\n\n![photo](a.png)\n", resolveImage: { _ in url })
        let size = try #require(harness.controller.imageMenu(at: 6)?.items.last?.submenu)
        let medium = try #require(size.items.first { $0.title == "Medium" })

        harness.textView.slateImageSize(medium)

        #expect(harness.markdown == "Intro\n\n![photo|420](a.png)\n")
        let image = try #require(harness.controller.storage.attribute(.attachment, at: 6, effectiveRange: nil) as? ImageAttachment)
        #expect(image.displaySize(width: 700) == CGSize(width: 420, height: 210))
        let again = try #require(harness.controller.imageMenu(at: 6)?.items.last?.submenu)
        #expect(again.items.first { $0.title == "Medium" }?.state == .on)
    }

    @Test func originalSizeRemovesTheWidth() throws {
        let harness = EditorHarness(markdown: "![photo|420](a.png)\n")
        let size = try #require(harness.controller.imageMenu(at: 0)?.items.last?.submenu)
        let original = try #require(size.items.first { $0.title == "Original Size" })

        harness.textView.slateImageSize(original)

        #expect(harness.markdown == "![photo](a.png)\n")
    }

    @Test func anImageWithAWidthKeepsItsTextOnSave() {
        let harness = EditorHarness(markdown: "![photo|300x200](a.png)\n")

        #expect(harness.markdown == "![photo|300x200](a.png)\n")
    }

    @Test func dragTheHandleToResize() throws {
        let picture = try TestPicture(size: CGSize(width: 400, height: 200))
        let url = picture.url
        let harness = EditorHarness(markdown: "Intro\n\n![](a.png)\n", resolveImage: { _ in url })
        let rect = try imageRect(harness, at: 6)
        harness.controller.hoverImage(at: CGPoint(x: rect.midX, y: rect.midY))
        let handle = harness.controller.imageHandle

        handle.onResize(6, 250)
        let image = try #require(harness.controller.storage.attribute(.attachment, at: 6, effectiveRange: nil) as? ImageAttachment)
        #expect(image.width == 250)
        handle.onFinish(6, 250)

        #expect(handle.isHidden == true || handle.location == 6)
        #expect(harness.markdown == "Intro\n\n![|250](a.png)\n")
    }

    @Test func hoverShowsTheResizeHandleAtTheCorner() throws {
        let picture = try TestPicture(size: CGSize(width: 200, height: 120))
        let url = picture.url
        let harness = EditorHarness(markdown: "Intro\n\n![](a.png)\n", resolveImage: { _ in url })
        let rect = try imageRect(harness, at: 6)

        harness.controller.hoverImage(at: CGPoint(x: rect.midX, y: rect.midY))

        let handle = harness.controller.imageHandle
        #expect(handle.isHidden == false)
        #expect(handle.location == 6)
        #expect(rect.contains(handle.frame))
        #expect(handle.frame.maxX > rect.midX)
    }
}
