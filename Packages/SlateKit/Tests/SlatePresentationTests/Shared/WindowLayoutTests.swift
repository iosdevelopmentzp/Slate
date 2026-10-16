import Foundation
import SlateMocks
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct WindowLayoutTests {
    @Test func startsWithTheDefaultSize() {
        let layout = WindowLayout(store: InMemoryKeyValueStore())

        #expect(layout.size == WindowLayout.defaultSize)
        #expect(layout.panelTopLeft == nil)
    }

    @Test func tooSmallStoredSizeGrowsToTheMinimum() {
        let store = InMemoryKeyValueStore()
        store.set([100, 100], forKey: "window.size")

        let layout = WindowLayout(store: store)

        #expect(layout.size == WindowLayout.minimumSize)
    }

    @Test func sizeAndPositionAreRemembered() {
        let store = InMemoryKeyValueStore()
        let first = WindowLayout(store: store)

        first.size = CGSize(width: 900, height: 600)
        first.panelTopLeft = CGPoint(x: 40, y: 800)
        let second = WindowLayout(store: store)

        #expect(second.size == CGSize(width: 900, height: 600))
        #expect(second.panelTopLeft == CGPoint(x: 40, y: 800))
    }
}
