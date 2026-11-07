import Foundation

struct NoteSuggestion: Equatable {
    let name: String
    let isNew: Bool

    static let limit = 8

    static func matches(for query: String, in names: [String]) -> [NoteSuggestion] {
        let wanted = query.trimmingCharacters(in: .whitespaces)
        guard wanted.isEmpty == false else {
            return names.prefix(limit).map { NoteSuggestion(name: $0, isNew: false) }
        }
        let ranked = names.compactMap { name -> (Int, String)? in
            guard let rank = rank(of: name, for: wanted) else { return nil }
            return (rank, name)
        }
        let found = ranked
            .sorted { $0.0 != $1.0 ? $0.0 < $1.0 : $0.1.localizedStandardCompare($1.1) == .orderedAscending }
            .prefix(limit)
            .map { NoteSuggestion(name: $0.1, isNew: false) }
        let exact = names.contains { $0.caseInsensitiveCompare(wanted) == .orderedSame }
        return exact ? found : Array(found.prefix(limit - 1)) + [NoteSuggestion(name: wanted, isNew: true)]
    }

    private static func rank(of name: String, for query: String) -> Int? {
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        if name.range(of: query, options: options.union(.anchored)) != nil { return 0 }
        let words = name.split { $0.isWhitespace || $0 == "-" || $0 == "_" }
        if words.contains(where: { $0.range(of: query, options: options.union(.anchored)) != nil }) { return 1 }
        if name.range(of: query, options: options) != nil { return 2 }
        return nil
    }
}
