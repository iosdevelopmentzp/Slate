import Foundation

struct InlineRun: Equatable {
    var text: String
    var style: InlineStyle
    var href: String?
    var isHardBreak = false
    var allowsWiki = false
    var imagePath: String?
    var imageAlt: String?
    var escapes: Set<Int>?

    var attributed: NSAttributedString {
        var attributes: [NSAttributedString.Key: Any] = [:]
        if style.isEmpty == false { attributes[.slateInline] = style.rawValue }
        if let href { attributes[.slateHref] = href }
        if isHardBreak { attributes[.slateHardBreak] = true }
        if let imagePath { attributes[.slateImagePath] = imagePath }
        if let imageAlt, imageAlt.isEmpty == false { attributes[.slateImageAlt] = imageAlt }
        return NSAttributedString(string: text, attributes: attributes)
    }
}
