import Testing
@testable import SlateData

@MainActor @Suite struct QuickLookSourceTests {
    @Test func goesAboveAHigherWindow() {
        #expect(QuickLookSource.level(for: 8, above: [0, 25]) == 26)
    }

    @Test func goesAboveAWindowAtTheSameLevel() {
        #expect(QuickLookSource.level(for: 25, above: [25]) == 26)
    }

    @Test func staysWhenItIsAlreadyOnTop() {
        #expect(QuickLookSource.level(for: 8, above: [0, 3]) == nil)
        #expect(QuickLookSource.level(for: 8, above: []) == nil)
    }
}
