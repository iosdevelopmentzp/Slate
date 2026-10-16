import Foundation
import Testing
@testable import SlateEditor

@Suite struct EditorConfigurationTests {
    @Test func standardProseLineHeightIsReadable() {
        #expect(EditorConfiguration.standard.lineHeightMultiple == 1.35)
    }
}
