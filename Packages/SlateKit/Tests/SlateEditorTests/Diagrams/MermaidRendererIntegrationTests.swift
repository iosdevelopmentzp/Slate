import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct MermaidRendererIntegrationTests {

    @Test func aFlowchartBecomesAPicture() async {
        let renderer = MermaidRenderer()

        let picture = await renderer.render("flowchart LR\n  A --> B", dark: false)

        #expect(picture.error == nil)
        #expect(picture.image != nil)
        #expect(picture.size.width > 0)
        #expect(picture.size.height > 0)
    }

    @Test func aDarkDiagramIsDrawnToo() async {
        let renderer = MermaidRenderer()

        let picture = await renderer.render("sequenceDiagram\n  App->>API: login", dark: true)

        #expect(picture.image != nil)
    }

    @Test func aBrokenDiagramGivesTheError() async {
        let renderer = MermaidRenderer()

        let picture = await renderer.render("flowchart LR\n  A --> ", dark: false)

        #expect(picture.image == nil)
        #expect(picture.error?.isEmpty == false)
    }
}
