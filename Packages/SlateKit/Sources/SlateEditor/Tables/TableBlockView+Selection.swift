import AppKit

extension TableBlockView {
    override var acceptsFirstResponder: Bool {
        cellSelection != nil
    }

    func selectCells(_ range: TableCellRange) {
        guard let range = range.clamped(to: attachment?.model ?? .empty()) else { return }
        if editing != nil {
            endEditing()
        }
        cellSelection = range
        window?.makeFirstResponder(self)
        host?.tableBeganEditing(self)
        reveal(range.head)
        needsDisplay = true
    }

    func selectWholeTable() {
        guard let model = attachment?.model, model.rowCount > 0, model.columnCount > 0 else { return }
        selectCells(TableCellRange(anchor: TableCellIndex(row: 0, column: 0), head: TableCellIndex(row: model.rowCount - 1, column: model.columnCount - 1)))
    }

    func clearCellSelection() {
        guard cellSelection != nil else { return }
        cellSelection = nil
        needsDisplay = true
        if editing == nil {
            host?.tableEndedEditing(self)
        }
    }

    override func resignFirstResponder() -> Bool {
        clearCellSelection()
        return true
    }

    func drawSelection(layout: TableLayout) {
        guard let range = cellSelection else { return }
        let first = layout.cellRect(range.topLeft)
        let last = layout.cellRect(TableCellIndex(row: range.rows.upperBound, column: range.columns.upperBound))
        let area = first.union(last).insetBy(dx: 1, dy: 1)
        NSColor.controlAccentColor.withAlphaComponent(0.14).setFill()
        area.fill()
        NSColor.controlAccentColor.setStroke()
        let border = NSBezierPath(roundedRect: area, xRadius: 2, yRadius: 2)
        border.lineWidth = 1.5
        border.stroke()
    }

    func neighbor(of index: TableCellIndex, rows: Int, columns: Int) -> TableCellIndex? {
        let next = TableCellIndex(row: index.row + rows, column: index.column + columns)
        return attachment?.model.contains(next) == true ? next : nil
    }

    func extendSelection(from anchor: TableCellIndex, to head: TableCellIndex) {
        selectCells(TableCellRange(anchor: anchor, head: head))
    }

    // MARK: Keys

    override func keyDown(with event: NSEvent) {
        guard cellSelection != nil else {
            super.keyDown(with: event)
            return
        }
        interpretKeyEvents([event])
    }

    override func doCommand(by selector: Selector) {
        guard let range = cellSelection else {
            super.doCommand(by: selector)
            return
        }
        let head = range.head
        switch selector {
        case #selector(NSResponder.moveUp(_:)): beginEditing(neighbor(of: head, rows: -1, columns: 0) ?? head)
        case #selector(NSResponder.moveDown(_:)): beginEditing(neighbor(of: head, rows: 1, columns: 0) ?? head)
        case #selector(NSResponder.moveLeft(_:)): beginEditing(neighbor(of: head, rows: 0, columns: -1) ?? head)
        case #selector(NSResponder.moveRight(_:)), #selector(NSResponder.insertTab(_:)): beginEditing(neighbor(of: head, rows: 0, columns: 1) ?? head)
        case #selector(NSResponder.moveUpAndModifySelection(_:)): extendSelection(from: range.anchor, to: neighbor(of: head, rows: -1, columns: 0) ?? head)
        case #selector(NSResponder.moveDownAndModifySelection(_:)): extendSelection(from: range.anchor, to: neighbor(of: head, rows: 1, columns: 0) ?? head)
        case #selector(NSResponder.moveLeftAndModifySelection(_:)): extendSelection(from: range.anchor, to: neighbor(of: head, rows: 0, columns: -1) ?? head)
        case #selector(NSResponder.moveRightAndModifySelection(_:)): extendSelection(from: range.anchor, to: neighbor(of: head, rows: 0, columns: 1) ?? head)
        case #selector(NSResponder.deleteBackward(_:)), #selector(NSResponder.deleteForward(_:)): clearSelectedCells()
        case #selector(NSResponder.insertNewline(_:)): beginEditing(head, caretAtEnd: true)
        case #selector(NSResponder.cancelOperation(_:)): beginEditing(range.anchor, caretAtEnd: true)
        default: super.doCommand(by: selector)
        }
    }

    override func insertText(_ insertString: Any) {
        guard let range = cellSelection else { return }
        let text = (insertString as? NSAttributedString)?.string ?? insertString as? String ?? ""
        beginEditing(range.anchor)
        guard editing == range.anchor else { return }
        cellEditor.selectAll(nil)
        cellEditor.insertText(text, replacementRange: cellEditor.selectedRange())
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard cellSelection != nil, window?.firstResponder === self, let command = KeyboardMap.command(for: event), case .inline(let flag) = command else {
            return super.performKeyEquivalent(with: event)
        }
        toggleSelectedCells(flag)
        return true
    }

    // MARK: Actions

    func clearSelectedCells() {
        guard let range = cellSelection else { return }
        change({ $0.clear(range) }, focus: nil)
    }

    func toggleSelectedCells(_ flag: InlineStyle) {
        guard let range = cellSelection else { return }
        change({ $0.toggle(flag, in: range) }, focus: nil)
    }

    func paste(_ source: TableModel) {
        let origin = cellSelection?.topLeft ?? editing ?? TableCellIndex(row: 0, column: 0)
        change({ $0.paste(source, at: origin) }, focus: nil)
        let end = TableCellIndex(row: origin.row + source.rowCount - 1, column: origin.column + source.columnCount - 1)
        selectCells(TableCellRange(anchor: origin, head: end))
    }

    @objc func copy(_ sender: Any?) {
        guard let attachment, let range = cellSelection else { return }
        host?.copyCells(attachment, range: range)
    }

    @objc func cut(_ sender: Any?) {
        copy(sender)
        clearSelectedCells()
    }

    @objc func paste(_ sender: Any?) {
        guard cellSelection != nil else { return }
        host?.pasteIntoCells(self)
    }

    @objc func delete(_ sender: Any?) {
        clearSelectedCells()
    }

    override func selectAll(_ sender: Any?) {
        selectWholeTable()
    }

    @objc func slateBold(_ sender: Any?) { toggleSelectedCells(.bold) }
    @objc func slateItalic(_ sender: Any?) { toggleSelectedCells(.italic) }
    @objc func slateStrikethrough(_ sender: Any?) { toggleSelectedCells(.strikethrough) }
    @objc func slateCode(_ sender: Any?) { toggleSelectedCells(.code) }
}
