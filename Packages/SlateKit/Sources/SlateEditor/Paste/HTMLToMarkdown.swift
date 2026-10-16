import AppKit

enum HTMLToMarkdown {
    static func convert(_ html: String) -> String? {
        guard let data = html.data(using: .utf8),
              let attributed = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil) else { return nil }
        var result = ""
        let string = attributed.string as NSString
        attributed.enumerateAttributes(in: NSRange(location: 0, length: attributed.length)) { attributes, range, _ in
            let piece = string.substring(with: range)
            let core = piece.trimmingCharacters(in: .whitespacesAndNewlines)
            guard core.isEmpty == false else {
                result += piece
                return
            }
            let leading = String(piece.prefix { $0.isWhitespace })
            let trailing = String(piece.reversed().prefix { $0.isWhitespace }.reversed())
            var text = core
            if let font = attributes[.font] as? NSFont {
                let traits = font.fontDescriptor.symbolicTraits
                if traits.contains(.bold) { text = "**\(text)**" }
                if traits.contains(.italic) { text = "*\(text)*" }
            }
            if let link = attributes[.link] {
                let target = (link as? URL)?.absoluteString ?? (link as? String) ?? ""
                if target.isEmpty == false { text = "[\(text)](\(target))" }
            }
            result += leading + text + trailing
        }
        return result.trimmingCharacters(in: .newlines)
    }
}
