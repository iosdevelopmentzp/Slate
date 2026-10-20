import AppKit

enum CodePalette {
    private static let colors: [CodeTokenKind: NSColor] = [
        .keyword: dynamic(light: 0xAD3DA4, dark: 0xFF7AB2),
        .string: dynamic(light: 0xC41A16, dark: 0xFF8170),
        .comment: dynamic(light: 0x707F8C, dark: 0x7F8C98),
        .number: dynamic(light: 0x1C00CF, dark: 0xD9C97C),
        .type: dynamic(light: 0x0B4F79, dark: 0x6BDFFF),
        .attribute: dynamic(light: 0x815F03, dark: 0xCC9768),
        .added: dynamic(light: 0x1A7F37, dark: 0x3FB950),
        .removed: dynamic(light: 0xCF222E, dark: 0xF85149),
        .meta: dynamic(light: 0x6F42C1, dark: 0xA371F7),
    ]

    static func color(for kind: CodeTokenKind) -> NSColor {
        colors[kind] ?? .labelColor
    }

    private static func dynamic(light: Int, dark: Int) -> NSColor {
        let lightColor = rgb(light)
        let darkColor = rgb(dark)
        return NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? darkColor : lightColor
        }
    }

    private static func rgb(_ value: Int) -> NSColor {
        NSColor(srgbRed: CGFloat((value >> 16) & 0xFF) / 255, green: CGFloat((value >> 8) & 0xFF) / 255, blue: CGFloat(value & 0xFF) / 255, alpha: 1)
    }
}
