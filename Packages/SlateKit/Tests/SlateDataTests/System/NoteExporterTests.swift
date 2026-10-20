import Foundation
import AppKit
import PDFKit
import SlateTestSupport
import Testing
@testable import SlateData

@Suite struct NoteExporterTests {
    private let folder: TemporaryDirectory

    init() throws {
        folder = try TemporaryDirectory()
    }

    @Test func copyToDownloadsKeepsTheFileName() async throws {
        let source = try folder.write("picture", to: "vault/_attachments/photo.png")
        let downloads = folder.url.appendingPathComponent("Downloads")
        try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)
        let exporter = NoteExporter(downloads: downloads)

        let saved = try await exporter.copyToDownloads(source)

        #expect(saved.lastPathComponent == "photo.png")
        #expect(try String(contentsOf: saved, encoding: .utf8) == "picture")
        #expect(FileManager.default.fileExists(atPath: source.path))
    }

    @Test func copyToDownloadsAddsANumberWhenTheNameIsTaken() async throws {
        let source = try folder.write("picture", to: "vault/_attachments/photo.png")
        _ = try folder.write("old", to: "Downloads/photo.png")
        let exporter = NoteExporter(downloads: folder.url.appendingPathComponent("Downloads"))

        let saved = try await exporter.copyToDownloads(source)

        #expect(saved.lastPathComponent == "photo 2.png")
    }

    @Test func aLongNoteMakesAPDFWithSeveralPages() async throws {
        let body = (1...120).map { "Line \($0) of a long note." }.joined(separator: "\n\n")

        let data = try await NoteExporter(downloads: folder.url).pdf(title: "Long", body: body, folder: nil)

        #expect(String(decoding: data.prefix(5), as: UTF8.self) == "%PDF-")
        #expect((PDFDocument(data: data)?.pageCount ?? 0) > 1)
    }

    @MainActor
    @Test func codeParagraphsGetSpaceAroundThem() {
        let text = NSMutableAttributedString(string: "Text\n", attributes: [.font: NSFont.systemFont(ofSize: 13)])
        text.append(NSAttributedString(string: "let a = 1\n", attributes: [.font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)]))
        text.append(NSAttributedString(string: "After", attributes: [.font: NSFont.systemFont(ofSize: 13)]))

        let spaced = NoteExporter.spacingCodeBlocks(text)
        let code = spaced.attribute(.paragraphStyle, at: 5, effectiveRange: nil) as? NSParagraphStyle

        #expect(code?.headIndent == 8)
        #expect(code?.paragraphSpacingBefore == 12)
        #expect(code?.paragraphSpacing == 12)
        #expect((spaced.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)?.headIndent ?? 0 == 0)
    }
}
