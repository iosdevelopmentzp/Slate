import Foundation
import SlateTestSupport
import Testing
@testable import SlateData

@Suite struct HTMLExporterTests {
    @Test func pageHasTheTitleAndTheBody() {
        let html = HTMLExporter().html(title: "A <b> & c", body: "**bold**\n\n- item")

        #expect(html.contains("<title>A &lt;b&gt; &amp; c</title>"))
        #expect(html.contains("<strong>bold</strong>"))
        #expect(html.contains("<li><p>item</p>"))
    }

    @Test func imagesNextToTheNoteAreEmbedded() throws {
        let folder = try TemporaryDirectory()
        _ = try folder.write("png bytes", to: "_attachments/shot 1.png")
        let notes = folder.url.appendingPathComponent("Notes", isDirectory: true)

        let html = HTMLExporter().html(title: "A", body: "![shot](<../_attachments/shot 1.png>) ![web](https://example.com/a.png)", folder: notes)

        #expect(html.contains("src=\"data:image/png;base64,\(Data("png bytes".utf8).base64EncodedString())\""))
        #expect(html.contains("src=\"https://example.com/a.png\""))
    }

    @Test func marksAndTablesHaveStyles() {
        let html = HTMLExporter().html(title: "A", body: "| a | b |\n|---|---|\n| 1 | <mark>2</mark> |")

        #expect(html.contains("<table>"))
        #expect(html.contains("<mark>2</mark>"))
        #expect(html.contains("mark { background"))
    }
}
