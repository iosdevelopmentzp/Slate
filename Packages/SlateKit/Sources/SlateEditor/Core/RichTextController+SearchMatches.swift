import AppKit

extension RichTextController {
    static let shortestMatch = 2

    var matchColor: NSColor {
        NSColor.findHighlightColor.withAlphaComponent(0.45)
    }

    func highlightMatches(of words: [String]) {
        clearMatchHighlights()
        let ranges = matchRanges(of: words)
        guard ranges.isEmpty == false, let layout = textView.textLayoutManager, let content = layout.textContentManager else { return }
        for range in ranges {
            guard let start = content.location(content.documentRange.location, offsetBy: range.location),
                  let end = content.location(start, offsetBy: range.length),
                  let textRange = NSTextRange(location: start, end: end)
            else { continue }
            layout.addRenderingAttribute(.backgroundColor, value: matchColor, for: textRange)
        }
        matchHighlights = ranges
    }

    func clearMatchHighlights() {
        guard matchHighlights.isEmpty == false else { return }
        matchHighlights = []
        guard let layout = textView.textLayoutManager else { return }
        layout.removeRenderingAttribute(.backgroundColor, for: layout.documentRange)
    }

    func matchRanges(of words: [String]) -> [NSRange] {
        let needles = Set(words.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { $0.count >= Self.shortestMatch })
        var ranges: [NSRange] = []
        for needle in needles {
            var searchRange = NSRange(location: 0, length: string.length)
            while searchRange.length > 0 {
                let found = string.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive], range: searchRange)
                guard found.location != NSNotFound, found.length > 0 else { break }
                ranges.append(found)
                searchRange = NSRange(location: NSMaxRange(found), length: string.length - NSMaxRange(found))
            }
        }
        return ranges.sorted { $0.location < $1.location }
    }
}
