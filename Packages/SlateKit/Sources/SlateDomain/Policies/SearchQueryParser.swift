import Foundation

package enum SearchQueryParser {
    package static func parse(_ text: String, now: Date, timeZone: TimeZone) -> SearchQuery {
        var query = SearchQuery()
        for token in tokens(of: text) {
            let excluded = token.text.hasPrefix("-") && token.text.count > 1 && token.quoted == false
            let body = excluded ? String(token.text.dropFirst()) : token.text
            if token.quoted {
                if token.excludedPhrase {
                    query.excludedTerms.append(body)
                } else {
                    query.phrases.append(body)
                }
                continue
            }
            if let filter = filter(body, now: now, timeZone: timeZone) {
                if excluded {
                    query.excludedFilters.append(filter)
                } else {
                    query.filters.append(filter)
                }
                continue
            }
            guard body.contains(where: { $0.isLetter || $0.isNumber }) else { continue }
            if excluded {
                query.excludedTerms.append(body)
            } else {
                query.terms.append(body)
            }
        }
        return query
    }

    package static func date(_ value: String, now: Date, timeZone: TimeZone) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: now)
        switch value.lowercased() {
        case "today": return today
        case "yesterday": return calendar.date(byAdding: .day, value: -1, to: today)
        default: break
        }
        if value.hasPrefix("-"), let unit = value.last, let amount = Int(value.dropFirst().dropLast()) {
            switch unit {
            case "d": return calendar.date(byAdding: .day, value: -amount, to: today)
            case "w": return calendar.date(byAdding: .day, value: -7 * amount, to: today)
            case "m": return calendar.date(byAdding: .month, value: -amount, to: today)
            case "y": return calendar.date(byAdding: .year, value: -amount, to: today)
            default: return nil
            }
        }
        let parts = value.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    private static func filter(_ token: String, now: Date, timeZone: TimeZone) -> SearchFilter? {
        guard let colon = token.firstIndex(of: ":") else { return nil }
        let key = token[..<colon].lowercased()
        var value = String(token[token.index(after: colon)...])
        if value.hasPrefix("\""), value.hasSuffix("\""), value.count >= 2 {
            value = String(value.dropFirst().dropLast())
        }
        guard value.isEmpty == false else { return nil }
        switch key {
        case "tag": return .tag(TagPolicy.normalized(value))
        case "space", "folder": return .space(value)
        case "type", "kind": return .type(value.lowercased())
        case "ticket": return .ticket(value)
        case "status": return .status(value.lowercased())
        case "is": return SearchFilter.State(rawValue: value.lowercased()).map(SearchFilter.state)
        case "has": return SearchFilter.Content(rawValue: value.lowercased()).map(SearchFilter.has)
        case "before": return date(value, now: now, timeZone: timeZone).map(SearchFilter.before)
        case "after": return date(value, now: now, timeZone: timeZone).map(SearchFilter.after)
        default: return nil
        }
    }

    private struct Token {
        var text: String
        var quoted: Bool
        var excludedPhrase: Bool
    }

    private static func tokens(of text: String) -> [Token] {
        var result: [Token] = []
        var current = ""
        var inQuotes = false
        var quotedToken = false
        var excludedPhrase = false
        func emit() {
            if quotedToken {
                if current.isEmpty == false {
                    result.append(Token(text: current, quoted: true, excludedPhrase: excludedPhrase))
                }
            } else if current.isEmpty == false {
                result.append(Token(text: current, quoted: false, excludedPhrase: false))
            }
            current = ""
            quotedToken = false
            excludedPhrase = false
        }
        for character in text {
            if character == "\"" {
                if inQuotes {
                    inQuotes = false
                    if quotedToken { emit() } else { current.append(character) }
                } else if current.isEmpty || current == "-" {
                    excludedPhrase = current == "-"
                    current = ""
                    quotedToken = true
                    inQuotes = true
                } else {
                    current.append(character)
                    inQuotes = true
                }
            } else if character.isWhitespace, inQuotes == false {
                emit()
            } else {
                current.append(character)
            }
        }
        emit()
        return result
    }
}
