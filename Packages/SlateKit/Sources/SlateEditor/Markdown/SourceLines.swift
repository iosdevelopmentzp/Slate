import Foundation
import Markdown

struct SourceLines {
    let lines: [String]

    func slice(_ range: SourceRange?) -> String? {
        guard let range, range.lowerBound.line == range.upperBound.line, lines.indices.contains(range.lowerBound.line - 1) else { return nil }
        let bytes = Array(lines[range.lowerBound.line - 1].utf8)
        let start = range.lowerBound.column - 1
        let end = range.upperBound.column - 1
        guard start >= 0, end <= bytes.count, start <= end else { return nil }
        return String(decoding: bytes[start..<end], as: UTF8.self)
    }
}
