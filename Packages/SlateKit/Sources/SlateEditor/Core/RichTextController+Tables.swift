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

    func moveIntoTable(_ selector: Selector) -> Bool {
        guard textView.selectedRange().length == 0 else { return false }
        let caretX = caretRect().midX
        textView.perform(selector, with: nil)
        let caret = textView.selectedRange().location
        guard let (attachment, location) = tableAround(caret) else { return true }
        let forward = selector == #selector(NSResponder.moveDown(_:)) || selector == #selector(NSResponder.moveRight(_:))
        let vertical = selector == #selector(NSResponder.moveUp(_:)) || selector == #selector(NSResponder.moveDown(_:))
        textView.scrollRangeToVisible(NSRange(location: location, length: 1))
        textView.textLayoutManager?.textViewportLayoutController.layoutViewport()
        let view = attachment.view()
        let model = attachment.model
        let column: Int
        if vertical {
            column = view.window == nil ? 0 : view.currentLayout.column(atX: view.convert(CGPoint(x: caretX, y: 0), from: textView).x)
        } else {
            column = forward ? 0 : model.columnCount - 1
        }
        let row = forward ? 0 : model.rowCount - 1
        view.beginEditing(TableCellIndex(row: row, column: column), caretAtEnd: vertical == false && forward == false)
        return true
    }

    private func tableAround(_ caret: Int) -> (TableAttachment, Int)? {
        for index in [caret, caret - 1] where index >= 0 && index < storage.length {
            if let table = storage.attribute(.attachment, at: index, effectiveRange: nil) as? TableAttachment {
                return (table, index)
            }
        }
        return nil
    }

    private func caretRect() -> CGRect {
        guard let window = textView.window else { return .zero }
        let screen = textView.firstRect(forCharacterRange: textView.selectedRange(), actualRange: nil)
        return textView.convert(window.convertFromScreen(screen), from: nil)
    }

    func undoInDocument(redo: Bool) {
        textView.window?.makeFirstResponder(textView)
        if redo {
            redoEdit()
        } else {
            undoEdit()
        }
    }

    func insertIntoCell(_ markdown: String, target: TableImageTarget) {
        guard let attachment = target.attachment else { return }
        let inline = markdown.components(separatedBy: .newlines).filter { $0.isEmpty == false }.joined(separator: " ")
        if let view = attachment.loadedView, view.editing == target.cell {
            view.insertInline(inline)
            return
        }
        var model = attachment.model
        let current = model.cell(target.cell).markdown
        model.setCell(target.cell, markdown: current.isEmpty ? inline : current + " " + inline)
        tableDidChange(attachment, model: model, before: attachment.block.model)
    }

    func imageAction(_ path: String, _ action: AttachmentAction) {
        handlers.attachment(path, action)
    }
}
