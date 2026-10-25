import AppKit
import Observation
import SlateDomain
import SlateUI

@MainActor
@Observable
final class WindowLayout {
    static let minimumSize = CGSize(width: 820, height: 520)
    static let defaultSize = CGSize(width: 1040, height: 680)
    static let sidebarWidths: ClosedRange<CGFloat> = 180...300
    static let defaultSidebarWidth: CGFloat = 220
    static let listWidths: ClosedRange<CGFloat> = 260...420
    static let defaultListWidth: CGFloat = 320
    static let trafficLightsWidth: CGFloat = 80
    static let windowAutosaveName = "SlateMainWindow"
    static let screenInset: CGFloat = 12

    var size: CGSize {
        didSet {
            guard size != oldValue else { return }
            store.set([Double(size.width), Double(size.height)], forKey: Keys.size)
        }
    }

    var isWindowOpen: Bool {
        didSet {
            guard isWindowOpen != oldValue else { return }
            store.set(isWindowOpen ? "open" : "hidden", forKey: Keys.windowOpen)
        }
    }

    var listWidth: CGFloat {
        didSet {
            guard listWidth != oldValue else { return }
            store.set(Int(listWidth), forKey: Keys.listWidth)
        }
    }

    var sidebarWidth: CGFloat {
        didSet {
            guard sidebarWidth != oldValue else { return }
            store.set(Int(sidebarWidth), forKey: Keys.sidebarWidth)
        }
    }

    var showsSidebar: Bool {
        didSet {
            guard showsSidebar != oldValue else { return }
            store.set(showsSidebar ? "shown" : "hidden", forKey: Keys.sidebar)
        }
    }

    var showsList: Bool {
        didSet {
            guard showsList != oldValue else { return }
            store.set(showsList ? "shown" : "hidden", forKey: Keys.list)
        }
    }

    var openCount = 0

    @ObservationIgnored private let store: any KeyValueStore

    init(store: any KeyValueStore) {
        self.store = store
        let stored = store.doubles(forKey: Keys.size)
        if let stored, stored.count == 2 {
            size = Self.clamped(CGSize(width: stored[0], height: stored[1]))
        } else {
            size = Self.defaultSize
        }
        let storedWidth = store.integer(forKey: Keys.listWidth)
        listWidth = storedWidth > 0 ? Self.clampedListWidth(CGFloat(storedWidth)) : Self.defaultListWidth
        let storedSidebarWidth = store.integer(forKey: Keys.sidebarWidth)
        sidebarWidth = storedSidebarWidth > 0 ? Self.clampedSidebarWidth(CGFloat(storedSidebarWidth)) : Self.defaultSidebarWidth
        showsSidebar = store.string(forKey: Keys.sidebar) != "hidden"
        showsList = store.string(forKey: Keys.list) != "hidden"
        isWindowOpen = store.string(forKey: Keys.windowOpen) != "hidden"
    }

    static func clampedListWidth(_ proposed: CGFloat) -> CGFloat {
        min(max(proposed, listWidths.lowerBound), listWidths.upperBound).rounded()
    }

    static func clampedSidebarWidth(_ proposed: CGFloat) -> CGFloat {
        min(max(proposed, sidebarWidths.lowerBound), sidebarWidths.upperBound).rounded()
    }

    static func clamped(_ proposed: CGSize) -> CGSize {
        clamped(proposed, to: usableArea(of: NSScreen.main)?.size ?? CGSize(width: 1440, height: 900))
    }

    static func usableArea(of screen: NSScreen?) -> NSRect? {
        screen?.visibleFrame.insetBy(dx: screenInset, dy: screenInset)
    }

    static func screen(containing point: CGPoint) -> NSScreen? {
        NSScreen.screens.first { $0.frame.insetBy(dx: -1, dy: -1).contains(point) }
    }

    private static func clamped(_ proposed: CGSize, to room: CGSize) -> CGSize {
        CGSize(
            width: min(max(proposed.width, minimumSize.width), room.width).rounded(.down),
            height: min(max(proposed.height, minimumSize.height), room.height).rounded(.down)
        )
    }

    private enum Keys {
        static let size = "window.size"
        static let windowOpen = "window.open"
        static let listWidth = "window.listWidth"
        static let sidebarWidth = "window.sidebarWidth"
        static let sidebar = "window.sidebar"
        static let list = "window.list"
    }
}
