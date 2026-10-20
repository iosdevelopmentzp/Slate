import Foundation

enum SectionKeys {
    static func keys(for headings: Set<Int>, in text: NSAttributedString) -> [String] {
        identified(in: text).filter { headings.contains($0.location) }.map(\.key)
    }

    static func headings(for keys: [String], in text: NSAttributedString) -> Set<Int> {
        let wanted = Set(keys)
        return Set(identified(in: text).filter { wanted.contains($0.key) }.map(\.location))
    }

    private static func identified(in text: NSAttributedString) -> [(key: String, location: Int)] {
        var seen: [String: Int] = [:]
        return OutlineItem.items(in: text).map { item in
            let base = "\(item.level) \(item.title)"
            let count = seen[base, default: 0]
            seen[base] = count + 1
            return (count == 0 ? base : "\(base) #\(count + 1)", item.location)
        }
    }
}
