import AppKit
import SlateDomain
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct PasteboardReaderTests {
    private let pasteboard = NSPasteboard(name: NSPasteboard.Name("slate.tests.\(UUID().uuidString)"))

    @Test func fileURLsComeFirst() {
        let url = URL(fileURLWithPath: "/tmp/spec.pdf")
        pasteboard.clearContents()
        pasteboard.writeObjects([url as NSURL])

        #expect(PasteboardReader.attachments(in: pasteboard) == [.file(url)])
    }

    @Test func pngDataIsAnImage() {
        pasteboard.clearContents()
        pasteboard.setData(Data([1, 2]), forType: .png)

        #expect(PasteboardReader.attachments(in: pasteboard) == [.image(Data([1, 2]), fileExtension: "png")])
    }

    @Test func plainTextIsNoAttachment() {
        pasteboard.clearContents()
        pasteboard.setString("hello", forType: .string)

        #expect(PasteboardReader.attachments(in: pasteboard).isEmpty)
    }
}
