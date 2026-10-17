import AppKit

extension RichTextController {
    func convertSelectionToTable() -> Bool {
        let paragraphs = paragraphRanges(covering: textView.selectedRange())
            .filter { block(at: $0.location).kind.isAttachment == false }
        guard let first = paragraphs.first, let last = paragraphs.last else { return false }
        let range = NSRange(location: first.location, length: NSMaxRange(contentRange(of: last)) - first.location)
        let texts = paragraphs.map { storage.attributedSubstring(from: contentRange(of: $0)) }
        guard range.length > 0, paragraphRanges(covering: range).count == paragraphs.count,
              let model = TableTextConversion.model(from: texts) else { return false }
        activeTable?.endEditing()
        let table = NSMutableAttributedString(string: RichText.attachmentString, attributes: BlockAttributes(kind: .table, table: TableBlock(model: model)).attributes)
        restyle(table, range: NSRange(location: 0, length: table.length))
        replace(range, with: table, selection: NSRange(location: range.location + 1, length: 0))
        return true
    }

    func convertTableToText(_ attachment: TableAttachment) {
        guard let location = location(of: attachment) else { return }
        let text = NSMutableAttributedString()
        for (index, line) in TableTextConversion.lines(of: attachment.model).enumerated() {
            if index > 0 {
                text.append(NSAttributedString(string: "\n"))
            }
            text.append(retagged(line.text, as: BlockAttributes()))
            for image in line.images {
                text.append(NSAttributedString(string: "\n"))
                text.append(NSAttributedString(string: RichText.attachmentString, attributes: BlockAttributes(kind: .image, imagePath: image.path, imageAlt: image.alt).attributes))
            }
        }
        restyle(text, range: NSRange(location: 0, length: text.length))
        textView.window?.makeFirstResponder(textView)
        replace(NSRange(location: location, length: 1), with: text, selection: NSRange(location: location + text.length, length: 0))
    }
}
