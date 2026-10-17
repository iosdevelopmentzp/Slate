import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct CellImageAttachmentTests {
    @Test func thumbnailsAre80PointsHighAndKeepTheShape() {
        let wide = NSImage(size: CGSize(width: 400, height: 200))

        let attachment = CellImageAttachment(path: "../_attachments/a.png", picture: wide, borderColor: .separatorColor)

        #expect(attachment.bounds.size == CGSize(width: 160, height: 80))
        #expect(attachment.image?.size == CGSize(width: 160, height: 80))
    }

    @Test func aMissingImageGetsASquare() {
        #expect(CellImageAttachment.size(of: nil) == CGSize(width: 80, height: 80))
    }
}
