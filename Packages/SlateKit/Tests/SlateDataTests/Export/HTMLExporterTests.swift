import Foundation
import Testing
@testable import SlateData

@Suite struct HTMLExporterTests {
    @Test func pageHasTheTitleAndTheBody() {
        let html = HTMLExporter().html(title: "A <b> & c", body: "**bold**\n\n- item")

        #expect(html.contains("<title>A &lt;b&gt; &amp; c</title>"))
        #expect(html.contains("<strong>bold</strong>"))
        #expect(html.contains("<li><p>item</p>"))
    }
}
