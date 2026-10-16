import Foundation

package enum CompletionPolicy {
    package static let limit = 20

    package static func noteNames(matching prefix: String, in summaries: [NoteSummary]) -> [String] {
        let wanted = prefix.trimmingCharacters(in: .whitespaces).lowercased()
        var seen = Set<String>()
        let names = summaries
            .sorted { $0.updated > $1.updated }
            .map(\.stem)
            .filter { seen.insert($0.lowercased()).inserted }
        guard wanted.isEmpty == false else { return Array(names.prefix(limit)) }
        let starts = names.filter { $0.lowercased().hasPrefix(wanted) }
        let contains = names.filter { $0.lowercased().hasPrefix(wanted) == false && $0.lowercased().contains(wanted) }
        return Array((starts + contains).prefix(limit))
    }

    package static func tags(matching prefix: String, in tags: [TagCount]) -> [String] {
        let wanted = TagPolicy.normalized(prefix)
        let matching = tags.filter { wanted.isEmpty || $0.tag.hasPrefix(wanted) }.sorted { ($1.count, $0.tag) < ($0.count, $1.tag) }
        return Array(matching.map(\.tag).prefix(limit))
    }
}
