import Foundation

package enum SearchHighlightPolicy {
    package static func ranges(of words: [String], in text: String) -> [NSRange] {
        let ns = text as NSString
        var ranges: [NSRange] = []
        for word in words where word.isEmpty == false {
            var search = NSRange(location: 0, length: ns.length)
            while search.length > 0 {
                let found = ns.range(of: word, options: [.caseInsensitive, .diacriticInsensitive], range: search)
                guard found.location != NSNotFound else { break }
                let startsWord = found.location == 0 || isBoundary(ns.character(at: found.location - 1))
                if startsWord {
                    ranges.append(found)
                }
                let next = found.upperBound
                search = NSRange(location: next, length: ns.length - next)
            }
        }
        return merged(ranges)
    }

    package static func titleScore(_ title: String, words: [String]) -> Int {
        guard let first = words.first?.lowercased() else { return 0 }
        let lower = title.lowercased()
        if lower.hasPrefix(first) { return 2 }
        return words.allSatisfy({ lower.contains($0.lowercased()) }) ? 1 : 0
    }

    private static func isBoundary(_ character: unichar) -> Bool {
        guard let scalar = Unicode.Scalar(character) else { return true }
        return CharacterSet.alphanumerics.contains(scalar) == false
    }

    private static func merged(_ ranges: [NSRange]) -> [NSRange] {
        let sorted = ranges.sorted { $0.location < $1.location }
        var result: [NSRange] = []
        for range in sorted {
            if let last = result.last, range.location <= last.upperBound {
                result[result.count - 1] = NSUnionRange(last, range)
            } else {
                result.append(range)
            }
        }
        return result
    }
}
