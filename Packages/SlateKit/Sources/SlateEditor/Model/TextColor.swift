import AppKit

nonisolated package enum TextColor: Int, CaseIterable, Hashable, Sendable {
    case red = 1
    case orange
    case green
    case blue
    case gray

    package init?(hex: String) {
        guard let match = Self.allCases.first(where: { $0.hex.caseInsensitiveCompare(hex) == .orderedSame }) else { return nil }
        self = match
    }

    package var title: String {
        switch self {
        case .red: "Red"
        case .orange: "Orange"
        case .green: "Green"
        case .blue: "Blue"
        case .gray: "Grey"
        }
    }

    package var hex: String {
        switch self {
        case .red: "#E5484D"
        case .orange: "#F76B15"
        case .green: "#30A46C"
        case .blue: "#0090FF"
        case .gray: "#8B8D98"
        }
    }

    private var darkHex: String {
        switch self {
        case .red: "#FF6369"
        case .orange: "#FF801F"
        case .green: "#3DD68C"
        case .blue: "#70B8FF"
        case .gray: "#B0B4BA"
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
        let light = NSColor(hex: hex, alpha: 1)
        let dark = NSColor(hex: darkHex, alpha: 1)
        return NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        }
    }
}
