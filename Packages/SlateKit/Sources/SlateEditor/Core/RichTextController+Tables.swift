import AppKit

extension RichTextController: TableHost {
    func location(of attachment: TableAttachment) -> Int? {
        var found: Int?
        storage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: storage.length)) { value, range, stop in
            if (value as? TableAttachment) === attachment {
                found = range.location
                stop.pointee = true
            }
        }
        return found
    }

    func tableDidChange(_ attachment: TableAttachment, model: TableModel, before: TableModel?) {
        guard let location = location(of: attachment) else { return }
        let range = NSRange(location: location, length: 1)
        var block = BlockAttributes(storage.attributes(at: location, effectiveRange: nil))
        block.table = TableBlock(model: model, source: block.table?.source)
        replace(range, with: retagged(storage.attributedSubstring(from: range), as: block), selection: textView.selectedRange())
        tableNeedsLayout(attachment)
    }

    func tableNeedsLayout(_ attachment: TableAttachment) {
        guard let location = location(of: attachment),
              let textLayout = textView.textLayoutManager,
              let content = textLayout.textContentManager,
              let start = content.location(content.documentRange.location, offsetBy: location),
              let end = content.location(start, offsetBy: 1),
              let range = NSTextRange(location: start, end: end)
        else { return }
        textLayout.invalidateLayout(for: range)
        textLayout.textViewportLayoutController.layoutViewport()
    }

    func leaveTable(_ attachment: TableAttachment, after: Bool) {
        let caret: Int
        if let location = location(of: attachment) {
            if after {
                caret = location + 2 <= storage.length ? location + 2 : location + 1
            } else {
                caret = max(location - 1, 0)
            }
        } else {
            caret = textView.selectedRange().location
        }
        textView.window?.makeFirstResponder(textView)
        textView.setSelectedRange(NSRange(location: min(caret, storage.length), length: 0))
        textView.scrollRangeToVisible(textView.selectedRange())
    }

    func deleteTable(_ attachment: TableAttachment) {
        guard let location = location(of: attachment) else { return }
        let paragraph = paragraphRange(at: location)
        textView.window?.makeFirstResponder(textView)
        replace(paragraph, with: NSAttributedString(), selection: NSRange(location: paragraph.location, length: 0))
    }

    func tableBeganEditing(_ view: TableBlockView) {
        if let activeTable, activeTable !== view {
            activeTable.endEditing()
        }
        activeTable = view
    }

    func tableEndedEditing(_ view: TableBlockView) {
        if activeTable === view {
            activeTable = nil
        }
    }

    func insertTable(_ model: TableModel = .empty(), editing: Bool = true) {
        activeTable?.endEditing()
        let block = BlockAttributes(kind: .table, table: TableBlock(model: model))
        insertBlocks(NSAttributedString(string: RichText.attachmentString, attributes: block.attributes))
        guard editing, let attachment = tableBefore(textView.selectedRange().location) else { return }
        textView.textLayoutManager?.textViewportLayoutController.layoutViewport()
        attachment.view().beginEditing(TableCellIndex(row: 0, column: 0))
    }

    func tableBefore(_ location: Int) -> TableAttachment? {
        let upper = min(location, storage.length) - 1
        guard upper >= 0 else { return nil }
        for index in stride(from: upper, through: max(upper - 2, 0), by: -1) {
            if let table = storage.attribute(.attachment, at: index, effectiveRange: nil) as? TableAttachment {
                return table
            }
        }
        return nil
    }

    func undoInDocument(redo: Bool) {
        textView.window?.makeFirstResponder(textView)
        if redo {
            redoEdit()
        } else {
            undoEdit()
        }
    }
}
