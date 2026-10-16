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

    @Test func listWidthAndSidebarAreRemembered() {
        let store = InMemoryKeyValueStore()
        let first = WindowLayout(store: store)
        #expect(first.listWidth == WindowLayout.defaultListWidth)
        #expect(first.showsSidebar)

        first.listWidth = 380
        first.showsSidebar = false
        let second = WindowLayout(store: store)

        #expect(second.listWidth == 380)
        #expect(second.showsSidebar == false)
    }

    @Test func listWidthStaysInItsRange() {
        #expect(WindowLayout.clampedListWidth(100) == 260)
        #expect(WindowLayout.clampedListWidth(900) == 420)
        #expect(WindowLayout.clampedListWidth(300.4) == 300)
    }
}
