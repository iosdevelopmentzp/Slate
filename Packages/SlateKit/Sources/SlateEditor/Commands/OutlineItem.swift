import Foundation

package struct OutlineItem: Identifiable, Hashable, Sendable {
    package let id: Int
    package let level: Int
    package let title: String
    package let location: Int

    package init(id: Int, level: Int, title: String, location: Int) {
        self.id = id
        self.level = level
        self.title = title
        self.location = location
    }

    package static func items(in text: String) -> [OutlineItem] {
        let tracker = FenceTracker(text: text as NSString)
        let ns = text as NSString
        return tracker.lines.enumerated().compactMap { index, line in
            guard case .heading(let level, let markLength) = line.kind else { return nil }
            let title = ns.substring(with: line.range).dropFirst(markLength).trimmingCharacters(in: .whitespaces)
            guard title.isEmpty == false else { return nil }
            return OutlineItem(id: index, level: level, title: title, location: line.start)
        }
    }
}
