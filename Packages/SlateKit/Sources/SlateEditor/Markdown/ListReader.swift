import Foundation
import Markdown

enum ListReader {

    static func read(_ list: ListItemContainer, indent: Int, group: Int, source: SourceLines) -> [ReadBlock]? {
        guard indent <= RichText.maxIndent else { return nil }
        let isOrdered = list is OrderedList
        var blocks: [ReadBlock] = []
        for item in list.listItems {
            let children = Array(item.children)
            var rest = children[...]
            var text = NSAttributedString()
            if let paragraph = rest.first as? Paragraph {
                guard MarkdownReader.isPlainParagraph(paragraph), let inline = InlineReader.read(paragraph.children, source: source) else { return nil }
                text = inline
                rest = rest.dropFirst()
            } else if rest.isEmpty == false {
                return nil
            }
            let attributes: BlockAttributes
            switch (isOrdered, item.checkbox) {
            case (true, .some):
                return nil
            case (true, .none):
                attributes = BlockAttributes(kind: .numbered, indent: indent, group: group)
            case (false, .some(let box)):
                attributes = BlockAttributes(kind: .checklist, indent: indent, isDone: box == .checked, group: group)
            case (false, .none):
                attributes = BlockAttributes(kind: .bullet, indent: indent, group: group)
            }
            blocks.append(ReadBlock(text: text, attributes: attributes))
            for child in rest {
                guard let nested = child as? ListItemContainer, let nestedBlocks = read(nested, indent: indent + 1, group: group, source: source) else { return nil }
                blocks += nestedBlocks
            }
        }
        return blocks
    }
}
