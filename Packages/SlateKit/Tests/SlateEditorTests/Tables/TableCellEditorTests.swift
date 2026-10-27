import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct TableCellEditorTests {
    @Test func aCellLeavesQuickLookToSlate() {
        #expect(TableCellEditor.make().acceptsPreviewPanelControl(nil) == false)
    }
}
