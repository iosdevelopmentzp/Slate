import Foundation
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
}
