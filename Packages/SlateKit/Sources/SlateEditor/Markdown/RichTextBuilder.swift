import Foundation

struct RichTextBuilder {
    private(set) var result = NSMutableAttributedString()
    private var previous: BlockAttributes?
    private var groups = 0

    mutating func nextGroup() -> Int {
        groups += 1
        return groups
    }

    mutating func append(_ text: NSAttributedString, block: BlockAttributes) {
        if let previous {
            result.append(NSAttributedString(string: "\n", attributes: previous.attributes))
        }
        let paragraph = NSMutableAttributedString(attributedString: text)
        paragraph.addAttributes(block.attributes, range: NSRange(location: 0, length: paragraph.length))
        result.append(paragraph)
        previous = block
    }
}
