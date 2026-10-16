import SwiftUI
import Testing
@testable import SlateUI

@Suite struct ThemeTests {
    @Test func surfaceAndBaseDiffer() {
        #expect(Theme.surface != Theme.base)
    }
}
