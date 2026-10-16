import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct EditorStoreAttachmentsTests {
    private let harness = StoreHarness()

    private var editor: EditorStore {
        harness.editor
    }

    private func open(_ path: String, id: String = "a") async throws {
        harness.seed(path, id: id, title: VaultPath(rawValue: path).stem)
        try await harness.index()
        harness.navigator.select(NoteID(rawValue: id))
        await editor.open(NoteID(rawValue: id))
    }

    @Test func pastedImageIsInsertedAsMarkdown() async throws {
        try await open("Inbox/A.md")

        await editor.pasteImage(Data([1]), fileExtension: "png")

        #expect(editor.insertion == MarkdownInsertion(token: 1, markdown: "![](../_attachments/20270115-110000-paste.png)"))
    }

    @Test func screenshotHidesThePanelAndInsertsTheImage() async throws {
        try await open("Tasks/A.md")
        var steps: [String] = []
        harness.panelVisibility.hideForCapture = { steps.append("hide") }
        harness.panelVisibility.showAfterCapture = { steps.append("show") }

        await editor.screenshot(.region)

        #expect(steps == ["hide", "show"])
        #expect(editor.insertion?.markdown == "![](../_attachments/20270115-110000-screenshot.png)")
    }

    @Test func cancelledScreenshotInsertsNothing() async throws {
        try await open("Tasks/A.md")
        harness.spies.capture.producesFile = false

        await editor.screenshot(.window)

        #expect(editor.insertion == nil)
    }

    @Test func linksResolveAgainstTheNoteFolder() async throws {
        try await open("Tasks/A.md")

        #expect(editor.resolveLink("../_attachments/a%20b.png") == URL(fileURLWithPath: "/vault/_attachments/a b.png"))
        #expect(editor.resolveLink("https://example.com") == nil)
    }

    @Test func webLinksOpenInTheBrowser() async throws {
        try await open("Tasks/A.md")

        await editor.openURL("https://example.com/x")

        #expect(harness.spies.workspace.calls == [.open(URL(string: "https://example.com/x")!)])
    }

    @Test func wikilinkSelectsTheNoteWithThatName() async throws {
        harness.seed("Notes/Other.md", id: "b", title: "Other")
        try await open("Tasks/A.md")

        await editor.openWikilink("other#Part")

        #expect(harness.navigator.selectedNote == NoteID(rawValue: "b"))
    }

    @Test func wikilinkToAMissingNoteMakesItInTheSameFolder() async throws {
        try await open("Tasks/A.md")

        await editor.openWikilink("Brand new")

        let created = try #require(harness.spies.index.indexed[VaultPath(rawValue: "Tasks/Brand new.md")])
        #expect(created.title == "Brand new")
        #expect(harness.navigator.selectedNote == created.id)
    }

    @Test func wikilinkWithAFolderPrefersThatFolder() async throws {
        harness.seed("Notes/Plan.md", id: "n", title: "Plan")
        harness.seed("Tasks/Plan.md", id: "t", title: "Plan")
        try await open("Inbox/A.md")

        await editor.openWikilink("Notes/Plan")

        #expect(harness.navigator.selectedNote == NoteID(rawValue: "n"))
    }

    @Test func quickLookOpensTheResolvedFile() async throws {
        try await open("Tasks/A.md")

        await editor.attachment("../_attachments/x.png", quickLook: true)

        #expect(harness.spies.workspace.calls == [.quickLook(URL(fileURLWithPath: "/vault/_attachments/x.png"))])
    }
}
