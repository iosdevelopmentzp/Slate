import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct EditorStoreExportTests {
    private let harness = StoreHarness()

    private func open(body: String) async throws {
        let path = harness.seed("Notes/Plan.md", id: "a", title: "Plan", body: body)
        try await harness.index()
        let summary = try #require(try await harness.ports.index.summaries(space: nil).first { $0.path == path })
        harness.navigator.select(summary.id)
        await harness.editor.open(summary.id)
    }

    @Test func htmlGoesToDownloadsWithLinksAsText() async throws {
        try await open(body: "See [[Log]] and ==this==.")

        await harness.editor.exportHTML()

        let page = try #require(harness.spies.exporter.saved["Plan.html"].map { String(decoding: $0, as: UTF8.self) })
        #expect(page == "<h1>Plan</h1>See Log and <mark>this</mark>.")
    }

    @Test func pdfGoesToDownloads() async throws {
        try await open(body: "Body")

        await harness.editor.exportPDF()

        #expect(harness.spies.exporter.saved["Plan.pdf"] == Data("%PDF Plan".utf8))
    }
}
