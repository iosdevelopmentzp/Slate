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
            var images: [ReadBlock] = []
            if let paragraph = rest.first as? Paragraph {
                guard let parts = itemText(paragraph, indent: indent, group: group, source: source) else { return nil }
                text = parts.text
                images = parts.images
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
            blocks += images
            for child in rest {
                if let paragraph = child as? Paragraph, paragraph.childCount == 1, let image = paragraph.child(at: 0) as? Image {
                    guard let block = imageBlock(image, indent: indent, group: group) else { return nil }
                    blocks.append(block)
                    continue
                }
                guard let nested = child as? ListItemContainer, let nestedBlocks = read(nested, indent: indent + 1, group: group, source: source) else { return nil }
                blocks += nestedBlocks
            }
        }
        return blocks
    }

    private static func itemText(_ paragraph: Paragraph, indent: Int, group: Int, source: SourceLines) -> (text: NSAttributedString, images: [ReadBlock])? {
        let children = Array(paragraph.children)
        if MarkdownReader.isPlainParagraph(paragraph) {
            return InlineReader.read(children, source: source).map { ($0, []) }
        }
        let isBreak: (Markup) -> Bool = { $0 is SoftBreak || $0 is LineBreak }
        guard let imageIndex = children.indices.first(where: { index in
            children[index] is Image && index > 0 && isBreak(children[index - 1]) && (index == children.count - 1 || isBreak(children[index + 1]))
        }) else { return nil }
        var images: [ReadBlock] = []
        for line in children[imageIndex...].split(whereSeparator: isBreak) {
            guard line.count == 1, let image = line.first as? Image, let block = imageBlock(image, indent: indent, group: group) else { return nil }
            images.append(block)
        }
        let first = Array(children[..<(imageIndex - 1)])
        guard first.contains(where: { $0 is Image }) == false, let text = InlineReader.read(first, source: source) else { return nil }
        return (text, images)
    }

    private static func imageBlock(_ image: Image, indent: Int, group: Int) -> ReadBlock? {
        guard image.title == nil, let path = image.source, path.isEmpty == false else { return nil }
        let alt = image.plainText
        return ReadBlock(text: NSAttributedString(string: RichText.attachmentString), attributes: BlockAttributes(kind: .image, indent: indent + 1, imagePath: path, imageAlt: alt.isEmpty ? nil : alt, group: group))
    }
}
