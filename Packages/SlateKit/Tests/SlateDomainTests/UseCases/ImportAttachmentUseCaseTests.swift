import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct ImportAttachmentUseCaseTests {
    private let note = VaultPath(rawValue: "Inbox/A.md")

    @Test func pastedImageIsWrittenAndLinked() async throws {
        let (ports, spies) = Ports.spies()

        let markdown = try await UseCases(ports: ports).importAttachment.execute(data: Data([1]), fileExtension: "png", for: note)

        #expect(markdown == "![](../_attachments/20270115-110000-paste.png)")
        #expect(spies.attachments.calls == [.write("20270115-110000-paste.png")])
    }

    @Test func aTakenNameGetsANumber() async throws {
        let (ports, spies) = Ports.spies()
        spies.attachments.seed("20270115-110000-paste.png")

        let markdown = try await UseCases(ports: ports).importAttachment.execute(data: Data([1]), fileExtension: "png", for: note)

        #expect(markdown == "![](../_attachments/20270115-110000-paste-2.png)")
    }

    @Test func filesAreCopiedWithTheirNameAsSource() async throws {
        let (ports, spies) = Ports.spies()
        let pdf = URL(fileURLWithPath: "/tmp/Design spec.pdf")
        let image = URL(fileURLWithPath: "/tmp/shot.jpg")

        let result = try await UseCases(ports: ports).importAttachment.execute(files: [pdf, image], for: note)

        #expect(result.markdown == [
            "[Design spec.pdf](../_attachments/20270115-110000-Design%20spec.pdf)",
            "![](../_attachments/20270115-110000-shot.jpg)",
        ])
        #expect(spies.attachments.calls.count == 2)
    }

    @Test func aLargeFileIsLinkedInPlace() async throws {
        let (ports, spies) = Ports.spies()
        let movie = URL(fileURLWithPath: "/tmp/movie.mov")
        spies.attachments.setExternalSize(AttachmentPolicy.maxImportSize + 1, for: movie)

        let result = try await UseCases(ports: ports).importAttachment.execute(files: [movie], for: note)

        #expect(result.markdown == ["[movie.mov](file:///tmp/movie.mov)"])
        #expect(result.linkedInPlace == ["movie.mov"])
        #expect(spies.attachments.calls.isEmpty)
    }
}
