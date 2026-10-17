import Foundation
import Testing
@testable import SlateDomain

@Suite struct AttachmentPolicyTests {
    private let note = VaultPath(rawValue: "Tasks/A.md")

    @Test func fileNameHasTheLocalTimeAndSource() {
        let name = AttachmentPolicy.fileName(source: "screenshot", fileExtension: "PNG", date: Date(timeIntervalSince1970: 1_800_000_000), timeZone: TimeZone(secondsFromGMT: 3 * 3_600)!)

        #expect(name == "20270115-110000-screenshot.png")
    }

    @Test func sourceFromAnOriginalNameIsCleanedAndCut() {
        #expect(AttachmentPolicy.source(forOriginalName: "Report: Q3/final.pdf") == "Report- Q3-final")
        #expect(AttachmentPolicy.source(forOriginalName: String(repeating: "a", count: 60) + ".txt").count == 40)
    }

    @Test func uniqueAppendsANumberBeforeTheExtension() {
        #expect(AttachmentPolicy.unique("a.png", among: ["b.png"]) == "a.png")
        #expect(AttachmentPolicy.unique("a.png", among: ["A.png", "a-2.png"]) == "a-3.png")
    }

    @Test func linkIsRelativeToTheNoteFolderAndEncoded() {
        #expect(AttachmentPolicy.relativeLink(to: "a b(1).png", from: note) == "../_attachments/a%20b%281%29.png")
        #expect(AttachmentPolicy.relativeLink(to: "x.png", from: VaultPath(rawValue: "Notes/Sub/B.md")) == "../../_attachments/x.png")
    }

    @Test func imagesAndFilesGetTheirMarkdown() {
        #expect(AttachmentPolicy.markdown(file: "x.png", from: note) == "![](../_attachments/x.png)")
        #expect(AttachmentPolicy.markdown(file: "1-report.pdf", originalName: "report.pdf", from: note) == "[report.pdf](../_attachments/1-report.pdf)")
    }

    @Test func linksResolveInsideTheVault() {
        #expect(AttachmentPolicy.vaultPath(ofLink: "../_attachments/a%20b.png", from: note) == "_attachments/a b.png")
        #expect(AttachmentPolicy.vaultPath(ofLink: "Other.md#part", from: note) == "Tasks/Other.md")
        #expect(AttachmentPolicy.vaultPath(ofLink: "../../outside.png", from: note) == nil)
        #expect(AttachmentPolicy.vaultPath(ofLink: "https://example.com/a.png", from: note) == nil)
        #expect(AttachmentPolicy.attachmentFile(ofLink: "../_attachments/x.png", from: note) == "x.png")
        #expect(AttachmentPolicy.attachmentFile(ofLink: "../Notes/x.png", from: note) == nil)
    }

    @Test func movingANoteDeeperRewritesItsAttachmentLinks() {
        let text = "![](../_attachments/a%20b.png)\n[Plan](../_attachments/plan.pdf#page=2) and [site](https://example.com/x.png) and ![](other/c.png)"

        let moved = AttachmentPolicy.rewriteLinks(in: text, from: VaultPath(rawValue: "Work/A.md"), to: VaultPath(rawValue: "Work/Clients/A.md"))

        #expect(moved == "![](../../_attachments/a%20b.png)\n[Plan](../../_attachments/plan.pdf#page=2) and [site](https://example.com/x.png) and ![](other/c.png)")
    }

    @Test func movingAtTheSameDepthKeepsTheText() {
        let text = "![](../_attachments/a.png)"

        #expect(AttachmentPolicy.rewriteLinks(in: text, from: VaultPath(rawValue: "Work/A.md"), to: VaultPath(rawValue: "Home/A.md")) == text)
    }
}
