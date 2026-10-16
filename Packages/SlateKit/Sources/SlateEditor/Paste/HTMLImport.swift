import AppKit

enum HTMLImport {

    static func fragment(from data: Data) -> NSAttributedString? {
        guard let source = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil) else { return nil }
        let result = NSMutableAttributedString()
        let body = BlockAttributes()
        source.enumerateAttributes(in: NSRange(location: 0, length: source.length)) { attributes, range, _ in
            var text = (source.string as NSString).substring(with: range)
            text = text.replacingOccurrences(of: "\u{2029}", with: "\n").replacingOccurrences(of: "\r", with: "\n")
            var style: InlineStyle = []
            if let font = attributes[.font] as? NSFont {
                let traits = font.fontDescriptor.symbolicTraits
                if traits.contains(.bold) { style.insert(.bold) }
                if traits.contains(.italic) { style.insert(.italic) }
                if traits.contains(.monoSpace) { style.insert(.code) }
            }
            if attributes[.strikethroughStyle] as? Int ?? 0 != 0 { style.insert(.strikethrough) }
            var plain = body.attributes
            if style.isEmpty == false { plain[.slateInline] = style.rawValue }
            if let link = attributes[.link] {
                plain[.slateHref] = (link as? URL)?.absoluteString ?? "\(link)"
            }
            result.append(NSAttributedString(string: text, attributes: plain))
        }
        while result.length > 0, result.string.hasSuffix("\n") {
            result.deleteCharacters(in: NSRange(location: result.length - 1, length: 1))
        }
        return result.length > 0 ? result : nil
    }
}
