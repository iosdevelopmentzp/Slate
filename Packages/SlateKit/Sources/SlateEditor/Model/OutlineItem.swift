import Foundation

struct OutlineItem: Equatable {
    let title: String
    let level: Int
    let location: Int

    static func items(in text: NSAttributedString) -> [OutlineItem] {
        let string = text.string as NSString
        var items: [OutlineItem] = []
        var location = 0
        while location < string.length {
            let paragraph = string.paragraphRange(for: NSRange(location: location, length: 0))
            let block = BlockAttributes(text.attributes(at: paragraph.location, effectiveRange: nil))
            if let level = block.kind.headingLevel {
                let title = string.substring(with: paragraph)
                    .replacingOccurrences(of: RichText.lineBreakString, with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if title.isEmpty == false {
                    items.append(OutlineItem(title: title, level: level, location: paragraph.location))
                }
            }
            location = NSMaxRange(paragraph)
        }
        return items
    }

    static func current(in items: [OutlineItem], at location: Int) -> OutlineItem? {
        items.last { $0.location <= location }
    }
}
