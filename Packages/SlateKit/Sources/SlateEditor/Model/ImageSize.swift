import Foundation

nonisolated enum ImageSize {
    private static let pattern = #"\|(\d+)(x\d+)?$"#

    static func width(in alt: String?) -> CGFloat? {
        guard let alt, let match = alt.range(of: pattern, options: .regularExpression) else { return nil }
        let digits = alt[match].dropFirst().prefix { $0.isNumber }
        guard let value = Int(digits), value > 0 else { return nil }
        return CGFloat(value)
    }

    static func label(of alt: String?) -> String {
        guard let alt else { return "" }
        guard let match = alt.range(of: pattern, options: .regularExpression) else { return alt }
        return String(alt[..<match.lowerBound])
    }

    static func alt(_ alt: String?, width: Int?) -> String? {
        let label = label(of: alt)
        guard let width else { return label.isEmpty ? nil : label }
        return "\(label)|\(width)"
    }
}
