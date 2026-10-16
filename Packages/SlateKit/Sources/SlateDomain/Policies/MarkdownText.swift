import Foundation

package enum MarkdownText {
    package struct ProseLine: Hashable, Sendable {
        package let index: Int
        package let text: String
        package let codeSpans: [NSRange]

        package func isInCode(_ range: NSRange) -> Bool {
            codeSpans.contains { NSIntersectionRange($0, range).length > 0 }
        }
    }

    package static func proseLines(of body: String) -> [ProseLine] {
        var result: [ProseLine] = []
        var fence: (marker: Character, count: Int)?
        for (index, line) in body.components(separatedBy: "\n").enumerated() {
            if let delimiter = fenceDelimiter(line) {
                if let open = fence {
                    if delimiter.marker == open.marker, delimiter.count >= open.count, delimiter.hasInfo == false {
                        fence = nil
                    }
                } else {
                    fence = (delimiter.marker, delimiter.count)
                }
                continue
            }
            guard fence == nil else { continue }
            result.append(ProseLine(index: index, text: line, codeSpans: codeSpans(in: line)))
        }
        return result
    }

    package static func codeSpans(in line: String) -> [NSRange] {
        guard line.contains("`") else { return [] }
        return codeSpan.matches(in: line, range: NSRange(location: 0, length: (line as NSString).length)).map(\.range)
    }

    private static func fenceDelimiter(_ line: String) -> (marker: Character, count: Int, hasInfo: Bool)? {
        let leading = line.prefix { $0 == " " }
        guard leading.count <= 3 else { return nil }
        let rest = line.dropFirst(leading.count)
        guard let marker = rest.first, marker == "`" || marker == "~" else { return nil }
        let run = rest.prefix { $0 == marker }.count
        guard run >= 3 else { return nil }
        let info = rest.dropFirst(run).trimmingCharacters(in: .whitespaces)
        if marker == "`", info.contains("`") { return nil }
        return (marker, run, info.isEmpty == false)
    }

    private static let codeSpan = try! NSRegularExpression(pattern: #"(`+)(.+?)\1"#)
}
