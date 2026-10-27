import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextViewTests {
    @Test func theTextViewLeavesQuickLookToSlate() {
        #expect(RichTextView().acceptsPreviewPanelControl(nil) == false)
    }
}
