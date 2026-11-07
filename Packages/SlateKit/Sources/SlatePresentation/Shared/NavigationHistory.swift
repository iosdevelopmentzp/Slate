import Foundation

struct NavigationHistory: Equatable {
    static let limit = 100

    private(set) var back: [NavigationPlace] = []
    private(set) var forward: [NavigationPlace] = []
    private(set) var current: NavigationPlace?

    var canGoBack: Bool {
        back.isEmpty == false
    }

    var canGoForward: Bool {
        forward.isEmpty == false
    }

    mutating func visit(_ place: NavigationPlace) {
        guard place.isEmpty == false else { return }
        guard let current else {
            self.current = place
            return
        }
        guard current.isSameTarget(as: place) == false else {
            self.current = place
            return
        }
        back.append(current)
        if back.count > Self.limit { back.removeFirst(back.count - Self.limit) }
        forward = []
        self.current = place
    }

    mutating func goBack(where isAvailable: (NavigationPlace) -> Bool) -> NavigationPlace? {
        while let place = back.popLast() {
            guard isAvailable(place) else { continue }
            if let current { forward.append(current) }
            current = place
            return place
        }
        return nil
    }

    mutating func goForward(where isAvailable: (NavigationPlace) -> Bool) -> NavigationPlace? {
        while let place = forward.popLast() {
            guard isAvailable(place) else { continue }
            if let current { back.append(current) }
            current = place
            return place
        }
        return nil
    }
}
