import Foundation

struct HeadingSection: Equatable {
    let heading: Int
    let level: Int
    let body: NSRange

    static func at(_ heading: Int, in text: NSAttributedString) -> HeadingSection? {
        let string = text.string as NSString
        guard heading >= 0, heading < string.length else { return nil }
        let paragraph = string.paragraphRange(for: NSRange(location: heading, length: 0))
        guard paragraph.location == heading, let level = level(at: heading, in: text) else { return nil }
        let start = NSMaxRange(paragraph)
        var end = start
        while end < string.length {
            if let next = self.level(at: end, in: text), next <= level { break }
            end = NSMaxRange(string.paragraphRange(for: NSRange(location: end, length: 0)))
        }
        return HeadingSection(heading: heading, level: level, body: NSRange(location: start, length: end - start))
    }

    static func containing(_ location: Int, in text: NSAttributedString) -> HeadingSection? {
        let string = text.string as NSString
        guard string.length > 0 else { return nil }
        var paragraph = string.paragraphRange(for: NSRange(location: min(max(location, 0), string.length - 1), length: 0))
        while true {
            if level(at: paragraph.location, in: text) != nil {
                return at(paragraph.location, in: text)
            }
            guard paragraph.location > 0 else { return nil }
            paragraph = string.paragraphRange(for: NSRange(location: paragraph.location - 1, length: 0))
        }
    }

    static func all(in text: NSAttributedString) -> [HeadingSection] {
        let string = text.string as NSString
        var sections: [HeadingSection] = []
        var location = 0
        while location < string.length {
            if let section = at(location, in: text), section.body.length > 0 {
                sections.append(section)
            }
            location = NSMaxRange(string.paragraphRange(for: NSRange(location: location, length: 0)))
        }
        return sections
    }

    private static func level(at location: Int, in text: NSAttributedString) -> Int? {
        BlockAttributes(text.attributes(at: location, effectiveRange: nil)).kind.headingLevel
    }
}
