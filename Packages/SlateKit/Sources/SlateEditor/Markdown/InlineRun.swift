import Foundation

struct InlineRun: Equatable {
    var text: String
    var style: InlineStyle
    var href: String?
    var isHardBreak = false
    var allowsWiki = false

    var attributed: NSAttributedString {
        var attributes: [NSAttributedString.Key: Any] = [:]
        if style.isEmpty == false { attributes[.slateInline] = style.rawValue }
        if let href { attributes[.slateHref] = href }
        if isHardBreak { attributes[.slateHardBreak] = true }
        return NSAttributedString(string: text, attributes: attributes)
    }
}
