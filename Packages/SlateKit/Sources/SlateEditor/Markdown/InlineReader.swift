import Foundation
import Markdown

enum InlineReader {

    static func read(_ children: some Sequence<Markup>, source: SourceLines, inCell: Bool = false) -> NSAttributedString? {
        var runs: [InlineRun] = []
        for child in children {
            guard collect(child, style: [], href: nil, source: source, inCell: inCell, into: &runs) else { return nil }
        }
        return WikilinkScanner.expand(merge(runs)).reduce(into: NSMutableAttributedString()) { result, run in
            result.append(run.attributed)
        }
    }

    private static func collect(_ markup: Markup, style: InlineStyle, href: String?, source: SourceLines, inCell: Bool, into runs: inout [InlineRun]) -> Bool {
        switch markup {
        case let text as Text:
            runs.append(InlineRun(text: text.string, style: style, href: href, allowsWiki: source.slice(text.range) == text.string))
        case let code as InlineCode:
            runs.append(InlineRun(text: code.code, style: style.union(.code), href: href))
        case is SoftBreak:
            runs.append(InlineRun(text: RichText.lineBreakString, style: [], href: href))
        case is LineBreak:
            runs.append(InlineRun(text: RichText.lineBreakString, style: [], href: href, isHardBreak: true))
        case let emphasis as Emphasis:
            return emphasis.children.allSatisfy { collect($0, style: style.union(.italic), href: href, source: source, inCell: inCell, into: &runs) }
        case let strong as Strong:
            return strong.children.allSatisfy { collect($0, style: style.union(.bold), href: href, source: source, inCell: inCell, into: &runs) }
        case let strike as Strikethrough:
            return strike.children.allSatisfy { collect($0, style: style.union(.strikethrough), href: href, source: source, inCell: inCell, into: &runs) }
        case let image as Image where inCell && href == nil:
            guard image.title == nil, let path = image.source, path.isEmpty == false else { return false }
            let alt = image.plainText
            runs.append(InlineRun(text: RichText.attachmentString, style: [], href: nil, imagePath: path, imageAlt: alt.isEmpty ? nil : alt))
        case let html as InlineHTML where inCell && isLineBreakTag(html.rawHTML):
            runs.append(InlineRun(text: RichText.lineBreakString, style: [], href: href))
        case let link as Link:
            guard href == nil, link.title == nil, let destination = link.destination, destination.isEmpty == false else { return false }
            let start = runs.count
            guard link.children.allSatisfy({ collect($0, style: style, href: destination, source: source, inCell: inCell, into: &runs) }) else { return false }
            if runs.count == start {
                runs.append(InlineRun(text: destination, style: style, href: destination))
            }
        default:
            return false
        }
        return true
    }

    private static func merge(_ runs: [InlineRun]) -> [InlineRun] {
        var merged: [InlineRun] = []
        for run in runs where run.text.isEmpty == false {
            if let last = merged.last, last.style == run.style, last.href == run.href, last.allowsWiki == run.allowsWiki, last.isHardBreak == false, run.isHardBreak == false, last.imagePath == nil, run.imagePath == nil {
                merged[merged.count - 1].text += run.text
            } else {
                merged.append(run)
            }
        }
        return merged
    }

    static func isLineBreakTag(_ html: String) -> Bool {
        html.range(of: #"^<br\s*/?>$"#, options: [.regularExpression, .caseInsensitive]) != nil
    }
}
