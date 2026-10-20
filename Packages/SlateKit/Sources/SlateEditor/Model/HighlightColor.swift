import AppKit

nonisolated package enum HighlightColor: Int, CaseIterable, Hashable, Sendable {
    case yellow = 1
    case green
    case blue
    case pink
    case purple

    package init?(hex: String) {
        guard let match = Self.allCases.first(where: { $0.hex.caseInsensitiveCompare(hex) == .orderedSame }) else { return nil }
        self = match
    }

    package var title: String {
        switch self {
        case .yellow: "Yellow"
        case .green: "Green"
        case .blue: "Blue"
        case .pink: "Pink"
        case .purple: "Purple"
        }
    }

    package var hex: String {
        switch self {
        case .yellow: "#FFF3A3A6"
        case .green: "#BBFABBA6"
        case .blue: "#ADCCFFA6"
        case .pink: "#FFB8EBA6"
        case .purple: "#D2B3FFA6"
        }
    }

    package var swatch: NSColor {
        NSColor(hex: hex, alpha: 1)
    }

    private static let displayColors = Dictionary(uniqueKeysWithValues: allCases.map { ($0, $0.makeDisplayColor()) })

    package var displayColor: NSColor {
        Self.displayColors[self] ?? swatch
    }

    private func makeDisplayColor() -> NSColor {
        let light = NSColor(hex: hex, alpha: 0.75)
        let dark = NSColor(hex: hex, alpha: 0.32)
        return NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        }
    }
}
