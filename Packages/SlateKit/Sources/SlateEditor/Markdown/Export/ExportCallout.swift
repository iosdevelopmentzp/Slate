import Foundation
import Markdown

struct ExportCallout {
    private static let marker = try! NSRegularExpression(pattern: #"^\[!([A-Za-z][A-Za-z0-9_-]*)\][+-]?\s*"#)

    let kind: CalloutKind
    let label: String
    let title: [Markup]
    let body: [Markup]
    let rest: [Markup]

    init?(_ quote: BlockQuote) {
        guard let paragraph = quote.child(at: 0) as? Paragraph else { return nil }
        let children = Array(paragraph.children)
        let leading = children.prefix { $0 is Text }
        let text = leading.compactMap { ($0 as? Text)?.string }.joined()
        let source = text as NSString
        guard let found = Self.marker.firstMatch(in: text, range: NSRange(location: 0, length: source.length)) else { return nil }
        let name = source.substring(with: found.range(at: 1))
        kind = CalloutKind(marker: name)
        label = CalloutKind.label(for: name)
        let remainder = source.substring(from: NSMaxRange(found.range))
        var inline: [Markup] = remainder.isEmpty ? [] : [Text(remainder)]
        inline += children.dropFirst(leading.count)
        let split = inline.firstIndex { $0 is SoftBreak || $0 is LineBreak }
        title = split.map { Array(inline[..<$0]) } ?? inline
        body = split.map { Array(inline[($0 + 1)...]) } ?? []
        rest = Array(quote.children.dropFirst())
    }

    var jiraMacro: String {
        switch kind {
        case .tip, .success, .answer: "tip"
        case .warning, .caution, .todo: "note"
        case .danger, .bug, .failure: "warning"
        default: "info"
        }
    }
}
