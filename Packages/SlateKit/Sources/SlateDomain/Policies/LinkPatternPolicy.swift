import Foundation

package enum LinkPatternPolicy {
    package struct Match: Hashable, Sendable {
        package let patternID: String
        package let range: NSRange
        package let text: String
        package let url: String
        package let label: String
    }

    package static func defaults(for settings: TrackerSettings) -> [LinkPattern] {
        var patterns: [LinkPattern] = []
        let tracker = trimmedBase(settings.trackerBaseURL)
        if tracker.isEmpty == false {
            patterns.append(LinkPattern(id: "jira", regex: settings.ticketPattern, url: tracker + "/browse/$1", label: "$1", icon: "ticket"))
        }
        let host = trimmedBase(settings.gitHostBaseURL)
        let project = settings.gitProjectPath.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
        if host.isEmpty == false, project.isEmpty == false {
            patterns.append(LinkPattern(id: "gitlab-mr", regex: #"(?<![\w/])!(\d+)\b"#, url: "\(host)/\(project)/-/merge_requests/$1", label: "!$1", icon: "arrow.triangle.merge"))
            patterns.append(LinkPattern(id: "gitlab-issue", regex: #"(?<![\w/&#])#(\d+)\b"#, url: "\(host)/\(project)/-/issues/$1", label: "#$1", icon: "circle.dotted"))
        }
        return patterns
    }

    package static func matches(in line: String, patterns: [LinkPattern]) -> [Match] {
        let ns = line as NSString
        var result: [Match] = []
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern.regex) else { continue }
            for match in regex.matches(in: line, range: NSRange(location: 0, length: ns.length)) where match.range.length > 0 {
                let groups = (0..<match.numberOfRanges).map { index -> String in
                    let range = match.range(at: index)
                    return range.location == NSNotFound ? "" : ns.substring(with: range)
                }
                result.append(Match(patternID: pattern.id, range: match.range, text: groups[0], url: expand(pattern.url, groups: groups), label: expand(pattern.label, groups: groups)))
            }
        }
        return result
    }

    package static func url(for patternID: String, match text: String, patterns: [LinkPattern]) -> String? {
        guard let pattern = patterns.first(where: { $0.id == patternID }) else { return nil }
        return matches(in: text, patterns: [pattern]).first?.url
    }

    package static func shortForm(for url: String, patterns: [LinkPattern]) -> String? {
        for pattern in patterns {
            guard let regex = templateRegex(pattern.url),
                  let match = regex.firstMatch(in: url, range: NSRange(location: 0, length: (url as NSString).length)) else { continue }
            let ns = url as NSString
            var groups = [url]
            for index in 1..<max(match.numberOfRanges, 1) {
                groups.append(ns.substring(with: match.range(at: index)))
            }
            return expand(pattern.label, groups: groups)
        }
        return nil
    }

    package static func expand(_ template: String, groups: [String]) -> String {
        var result = template
        for index in stride(from: min(groups.count - 1, 9), through: 1, by: -1) {
            result = result.replacingOccurrences(of: "$\(index)", with: groups[index])
        }
        return result
    }

    private static func templateRegex(_ template: String) -> NSRegularExpression? {
        guard template.contains("$1") else { return nil }
        var pattern = NSRegularExpression.escapedPattern(for: template)
        for index in 1...9 {
            pattern = pattern.replacingOccurrences(of: "\\$\(index)", with: "([^/?#&]+)")
        }
        return try? NSRegularExpression(pattern: "^" + pattern + "/?(?:[?#].*)?$")
    }

    private static func trimmedBase(_ url: String) -> String {
        var text = url.trimmingCharacters(in: .whitespaces)
        while text.hasSuffix("/") { text.removeLast() }
        return text
    }
}
