import Foundation

enum InlineHTMLTag: Equatable {
    case openHighlight(HighlightColor)
    case closeHighlight
    case openTextColor(TextColor)
    case closeTextColor

    private static let color = #"(#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?)"#
    private static let openMark = try! NSRegularExpression(pattern: #"^<mark\s+style\s*=\s*"\s*background(?:-color)?\s*:\s*"# + color + #"\s*;?\s*"\s*>$"#, options: .caseInsensitive)
    private static let openSpan = try! NSRegularExpression(pattern: #"^<span\s+style\s*=\s*"\s*color\s*:\s*"# + color + #"\s*;?\s*"\s*>$"#, options: .caseInsensitive)
    private static let closeMark = try! NSRegularExpression(pattern: #"^</mark\s*>$"#, options: .caseInsensitive)
    private static let closeSpan = try! NSRegularExpression(pattern: #"^</span\s*>$"#, options: .caseInsensitive)

    init?(_ html: String) {
        if let hex = Self.capture(Self.openMark, in: html) {
            guard let highlight = HighlightColor(hex: hex) else { return nil }
            self = .openHighlight(highlight)
        } else if let hex = Self.capture(Self.openSpan, in: html) {
            guard let color = TextColor(hex: hex) else { return nil }
            self = .openTextColor(color)
        } else if Self.matches(Self.closeMark, html) {
            self = .closeHighlight
        } else if Self.matches(Self.closeSpan, html) {
            self = .closeTextColor
        } else {
            return nil
        }
    }

    static func open(_ highlight: HighlightColor) -> String {
        "<mark style=\"background: \(highlight.hex);\">"
    }

    static func open(_ color: TextColor) -> String {
        "<span style=\"color: \(color.hex);\">"
    }

    static let closingHighlight = "</mark>"
    static let closingTextColor = "</span>"

    private static func capture(_ regex: NSRegularExpression, in html: String) -> String? {
        let range = NSRange(location: 0, length: (html as NSString).length)
        guard let match = regex.firstMatch(in: html, range: range), match.numberOfRanges > 1 else { return nil }
        return (html as NSString).substring(with: match.range(at: 1))
    }

    private static func matches(_ regex: NSRegularExpression, _ html: String) -> Bool {
        regex.firstMatch(in: html, range: NSRange(location: 0, length: (html as NSString).length)) != nil
    }
}
