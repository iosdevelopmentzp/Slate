import Foundation
import GRDB
import SlateDomain

struct SearchSQL: Sendable {
    var clauses: [String] = []
    var arguments: [DatabaseValue] = []

    init(query: SearchQuery) {
        for filter in query.filters {
            add(filter, negated: false)
        }
        for filter in query.excludedFilters {
            add(filter, negated: true)
        }
        let excluded = FTSMatchBuilder.match(terms: query.excludedTerms, phrases: [])
        if excluded.isEmpty == false {
            let any = query.excludedTerms.compactMap { term -> String? in
                let match = FTSMatchBuilder.match(terms: [term], phrases: [])
                return match.isEmpty ? nil : match
            }.joined(separator: " OR ")
            clauses.append("n.rowid NOT IN (SELECT rowid FROM notes_fts WHERE notes_fts MATCH ?)")
            arguments.append(any.databaseValue)
        }
    }

    var whereClause: String {
        clauses.isEmpty ? "1" : clauses.joined(separator: " AND ")
    }

    private mutating func add(_ filter: SearchFilter, negated: Bool) {
        let (sql, values) = Self.clause(for: filter)
        clauses.append(negated ? "NOT (\(sql))" : sql)
        arguments.append(contentsOf: values.map(\.databaseValue))
    }

    private static func clause(for filter: SearchFilter) -> (String, [any DatabaseValueConvertible]) {
        switch filter {
        case .tag(let tag):
            return ("EXISTS (SELECT 1 FROM tags t WHERE t.note_id = n.id AND (t.tag = ? OR substr(t.tag, 1, ?) = ?))", [tag, tag.count + 1, tag + "/"])
        case .space(let space):
            return ("n.space = ? COLLATE NOCASE", [space])
        case .type(let type):
            return ("n.type = ?", [type])
        case .ticket(let ticket):
            return ("n.ticket = ? COLLATE NOCASE", [ticket])
        case .status(let status):
            return ("n.status = ?", [status])
        case .state(.todo):
            return ("n.open_todos > 0", [])
        case .state(.pinned):
            return ("n.pinned = 1", [])
        case .state(.conflict):
            return ("n.in_conflict = 1", [])
        case .state(.trashed):
            return ("0", [])
        case .has(.image):
            return ("n.has_image = 1", [])
        case .has(.code):
            return ("n.has_code = 1", [])
        case .has(.link):
            return ("n.has_link = 1", [])
        case .has(.tag):
            return ("EXISTS (SELECT 1 FROM tags t WHERE t.note_id = n.id)", [])
        case .before(let date):
            return ("n.updated < ?", [date.timeIntervalSince1970])
        case .after(let date):
            return ("n.updated >= ?", [date.timeIntervalSince1970])
        }
    }
}
