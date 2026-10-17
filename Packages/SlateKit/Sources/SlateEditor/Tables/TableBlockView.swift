import AppKit

final class TableBlockView: NSView, NSTextViewDelegate {
    weak var attachment: TableAttachment?
    private(set) var editing: TableCellIndex?
    private(set) var before: TableModel?
    private let editor = TableCellEditor.make()
    private var isHovered = false
    private var isCommitting = false
    private var confirmation: NSView?
    private var tracking: NSTrackingArea?
    private var commitTask: Task<Void, Never>?
    private var pendingFocus: (index: TableCellIndex, atEnd: Bool)?
    private var keptSelection: NSRange?
    static let commitDelay: Duration = .seconds(2)

    init(attachment: TableAttachment) {
        self.attachment = attachment
        super.init(frame: .zero)
        editor.table = self
        editor.delegate = self
        registerForDraggedTypes(RichTextController.cellDropTypes)
        setAccessibilityRole(.table)
        setAccessibilityElement(true)
        updateAccessibility()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var isFlipped: Bool {
        true
    }

    var host: (any TableHost)? {
        attachment?.host
    }

    private var model: TableModel {
        attachment?.model ?? .empty()
    }

    var currentLayout: TableLayout {
        guard let attachment else { return TableLayout(columnWidths: [], rowHeights: []) }
        return attachment.layout(width: attachment.lastWidth)
    }

    func modelChanged() {
        updateAccessibility()
        if isCommitting == false, editing != nil {
            editor.removeFromSuperview()
            editing = nil
            before = nil
            host?.tableEndedEditing(self)
        }
        if let editing, model.contains(editing) == false {
            endEditing(commit: false)
        }
        positionEditor()
        needsDisplay = true
    }

    private func updateAccessibility() {
        setAccessibilityLabel("Table, \(model.rowCount) rows, \(model.columnCount) columns")
    }

    override func layout() {
        super.layout()
        positionEditor()
    }

    private func positionEditor() {
        guard let editing else { return }
        editor.frame = currentLayout.textRect(editing)
    }

    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let attachment else { return }
        let layout = currentLayout
        let colors = attachment.style.colors
        let bounds = CGRect(origin: .zero, size: layout.size)
        guard bounds.width > 0 else { return }
        let shape = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: TableLayout.radius, yRadius: TableLayout.radius)
        NSGraphicsContext.saveGraphicsState()
        shape.addClip()
        colors.codeBackground.setFill()
        CGRect(x: 0, y: 0, width: bounds.width, height: layout.rowHeights.first ?? 0).fill()
        colors.divider.setFill()
        var x: CGFloat = 0
        for width in layout.columnWidths.dropLast() {
            x += width
            CGRect(x: x - 0.5, y: 0, width: 1, height: bounds.height).fill()
        }
        var y: CGFloat = 0
        for height in layout.rowHeights.dropLast() {
            y += height
            CGRect(x: 0, y: y - 0.5, width: bounds.width, height: 1).fill()
        }
        NSGraphicsContext.restoreGraphicsState()
        colors.imageBorder.setStroke()
        shape.lineWidth = 1
        shape.stroke()
        for row in 0..<model.rowCount {
            for column in 0..<model.columnCount {
                let index = TableCellIndex(row: row, column: column)
                guard index != editing else { continue }
                attachment.text(index).draw(with: layout.textRect(index), options: [.usesLineFragmentOrigin, .usesFontLeading])
            }
        }
        if isHovered {
            drawHandles(layout: layout, colors: colors)
        }
    }

    private func drawHandles(layout: TableLayout, colors: EditorColors) {
        for (rect, _) in handles(layout: layout) {
            let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)
            colors.codeBackground.setFill()
            path.fill()
            colors.secondaryText.setFill()
            let center = CGPoint(x: rect.midX, y: rect.midY)
            CGRect(x: center.x - 4, y: center.y - 0.75, width: 8, height: 1.5).fill()
            CGRect(x: center.x - 0.75, y: center.y - 4, width: 1.5, height: 8).fill()
        }
    }

    enum Handle {
        case column
        case row
    }

    func handles(layout: TableLayout) -> [(CGRect, Handle)] {
        let size = layout.size
        return [
            (CGRect(x: size.width + 4, y: 0, width: 14, height: size.height), .column),
            (CGRect(x: 0, y: size.height + 4, width: size.width, height: 14), .row),
        ]
    }

    // MARK: Mouse

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self)
        addTrackingArea(area)
        tracking = area
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let layout = currentLayout
        if let handle = handles(layout: layout).first(where: { $0.0.insetBy(dx: -2, dy: -2).contains(point) })?.1 {
            switch handle {
            case .column: addColumn(at: model.columnCount, focus: TableCellIndex(row: 0, column: model.columnCount))
            case .row: addRow(at: model.rowCount, focus: TableCellIndex(row: model.rowCount, column: 0))
            }
            return
        }
        guard let index = layout.cell(at: point) else { return }
        beginEditing(index)
        guard editing == index, editor.window != nil else { return }
        let local = editor.convert(event.locationInWindow, from: nil)
        if event.clickCount > 1, let path = editor.imagePath(at: local) {
            host?.imageAction(path, .quickLook)
            return
        }
        let caret = min(editor.characterIndexForInsertion(at: local), (editor.string as NSString).length)
        editor.setSelectedRange(NSRange(location: caret, length: 0))
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        guard let index = currentLayout.cell(at: point) else { return nil }
        let menu = TableMenu.menu(for: index, model: model, target: self)
        beginEditing(index)
        guard editing == index, editor.window != nil, let path = editor.imagePath(at: editor.convert(event.locationInWindow, from: nil)) else { return menu }
        return ImageMenu.prepend(path: path, target: self, action: #selector(cellImageAction(_:)), to: menu)
    }

    @objc func cellImageAction(_ sender: NSMenuItem) {
        guard let choice = sender.representedObject as? ImageMenuChoice else { return }
        host?.imageAction(choice.path, choice.action)
    }

    // MARK: Editing

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        if newWindow == nil, editing != nil, window?.firstResponder === editor {
            keptSelection = editor.selectedRange()
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        if let kept = keptSelection, editing != nil {
            keptSelection = nil
            window.makeFirstResponder(editor)
            editor.setSelectedRange(kept)
            return
        }
        guard let pending = pendingFocus else { return }
        pendingFocus = nil
        beginEditing(pending.index, caretAtEnd: pending.atEnd)
    }

    func beginEditing(_ index: TableCellIndex, caretAtEnd: Bool = false) {
        guard let attachment, model.contains(index) else { return }
        guard window != nil else {
            pendingFocus = (index, caretAtEnd)
            return
        }
        if let editing, editing != index {
            finishCell()
        }
        if before == nil {
            before = attachment.block.model
        }
        editing = index
        let alignment = index.column < model.columns.count ? model.columns[index.column].alignment : .none
        editor.load(attachment.text(index), style: attachment.style, header: index.row == 0, alignment: alignment)
        if editor.superview !== self {
            addSubview(editor)
        }
        positionEditor()
        window?.makeFirstResponder(editor)
        editor.setSelectedRange(NSRange(location: caretAtEnd ? (editor.string as NSString).length : 0, length: 0))
        host?.tableBeganEditing(self)
        needsDisplay = true
    }

    func endEditing(commit: Bool = true) {
        commitTask?.cancel()
        commitTask = nil
        if commit {
            finishCell()
        }
        editing = nil
        before = nil
        editor.removeFromSuperview()
        host?.tableEndedEditing(self)
        needsDisplay = true
    }

    private func finishCell() {
        commitTask?.cancel()
        commitTask = nil
        guard let attachment, let editing else { return }
        var live = attachment.model
        live.setCell(editing, markdown: editor.markdown)
        attachment.setLiveModel(live)
        commit()
    }

    func commit() {
        guard let attachment else { return }
        let committed = attachment.block.model
        let current = attachment.model
        guard current != committed else {
            before = nil
            return
        }
        isCommitting = true
        host?.tableDidChange(attachment, model: current, before: committed)
        isCommitting = false
        before = nil
        positionEditor()
    }

    func textDidChange(_ notification: Notification) {
        guard let attachment, let editing else { return }
        var live = attachment.model
        live.setCell(editing, markdown: editor.markdown)
        let oldSize = currentLayout.size
        attachment.setLiveModel(live)
        if currentLayout.size != oldSize {
            host?.tableNeedsLayout(attachment)
        }
        positionEditor()
        needsDisplay = true
        commitTask?.cancel()
        commitTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: Self.commitDelay)
            guard Task.isCancelled == false, let self else { return }
            commit()
        }
    }

    func textDidEndEditing(_ notification: Notification) {
        Task { @MainActor [weak self] in
            guard let self, editing != nil, keptSelection == nil, window != nil, window?.firstResponder !== editor else { return }
            endEditing()
        }
    }

    func textView(_ textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        guard let editing else { return false }
        let last = TableCellIndex(row: model.rowCount - 1, column: model.columnCount - 1)
        let selection = editor.selectedRange()
        let length = (editor.string as NSString).length
        switch selector {
        case #selector(NSResponder.insertNewline(_:)):
            if NSApp?.currentEvent?.modifierFlags.contains(.shift) == true {
                insertCellLineBreak()
            } else {
                moveDown(from: editing, addingRow: true)
            }
        case #selector(NSResponder.insertLineBreak(_:)), #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)):
            insertCellLineBreak()
        case #selector(NSResponder.insertTab(_:)):
            if editing == last {
                finishCell()
                addRow(at: model.rowCount, focus: TableCellIndex(row: model.rowCount, column: 0))
            } else if editing.column + 1 < model.columnCount {
                beginEditing(TableCellIndex(row: editing.row, column: editing.column + 1))
            } else {
                beginEditing(TableCellIndex(row: editing.row + 1, column: 0))
            }
        case #selector(NSResponder.insertBacktab(_:)):
            if editing.column > 0 {
                beginEditing(TableCellIndex(row: editing.row, column: editing.column - 1), caretAtEnd: true)
            } else if editing.row > 0 {
                beginEditing(TableCellIndex(row: editing.row - 1, column: model.columnCount - 1), caretAtEnd: true)
            }
        case #selector(NSResponder.moveUp(_:)):
            if hasLineBreak(before: selection.location) {
                return false
            } else if editing.row == 0 {
                leave(after: false)
            } else {
                beginEditing(TableCellIndex(row: editing.row - 1, column: editing.column))
            }
        case #selector(NSResponder.moveDown(_:)):
            guard hasLineBreak(after: NSMaxRange(selection)) == false else { return false }
            moveDown(from: editing, addingRow: false)
        case #selector(NSResponder.moveLeft(_:)):
            guard editing == TableCellIndex(row: 0, column: 0), selection == NSRange(location: 0, length: 0) else { return false }
            leave(after: false)
        case #selector(NSResponder.moveRight(_:)):
            guard editing == last, selection == NSRange(location: length, length: 0) else { return false }
            leave(after: true)
        case #selector(NSResponder.cancelOperation(_:)):
            leave(after: true)
        default:
            return false
        }
        return true
    }

    func textView(_ view: NSTextView, shouldChangeTextIn range: NSRange, replacementString: String?) -> Bool {
        guard let replacementString, replacementString.contains(where: { $0 == "\n" || $0 == "\r" || $0 == "\r\n" }) else { return true }
        let lines = replacementString
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\n", with: RichText.lineBreakString)
        editor.insertText(lines, replacementRange: range)
        return false
    }

    func insertCellLineBreak() {
        editor.insertText(RichText.lineBreakString, replacementRange: editor.selectedRange())
    }

    private func hasLineBreak(before location: Int) -> Bool {
        let text = editor.string as NSString
        return text.substring(to: min(location, text.length)).contains(RichText.lineBreak)
    }

    private func hasLineBreak(after location: Int) -> Bool {
        let text = editor.string as NSString
        return text.substring(from: min(location, text.length)).contains(RichText.lineBreak)
    }

    func undoManager(for view: NSTextView) -> UndoManager? {
        editor.cellUndo
    }

    private func moveDown(from editing: TableCellIndex, addingRow: Bool) {
        if editing.row + 1 < model.rowCount {
            beginEditing(TableCellIndex(row: editing.row + 1, column: editing.column))
        } else if addingRow {
            finishCell()
            addRow(at: model.rowCount, focus: TableCellIndex(row: model.rowCount, column: editing.column))
        } else {
            leave(after: true)
        }
    }

    func leave(after: Bool) {
        guard let attachment else { return }
        endEditing()
        host?.leaveTable(attachment, after: after)
    }

    func undoOutside() {
        endEditing()
        host?.undoInDocument(redo: false)
    }

    func redoOutside() {
        endEditing()
        host?.undoInDocument(redo: true)
    }

    // MARK: Structure

    func change(_ transform: (inout TableModel) -> Void, focus: TableCellIndex?) {
        guard let attachment else { return }
        if editing != nil {
            finishCell()
        }
        var updated = attachment.model
        transform(&updated)
        attachment.setLiveModel(updated)
        let wasEditing = editing != nil || focus != nil
        commit()
        if let focus, updated.contains(focus) {
            beginEditing(focus)
        } else if wasEditing, let editing, updated.contains(editing) {
            beginEditing(editing)
        } else if editing != nil {
            endEditing(commit: false)
        }
    }

    func addRow(at row: Int, focus: TableCellIndex?) {
        change({ $0.insertRow(at: row) }, focus: focus)
    }

    func addColumn(at column: Int, focus: TableCellIndex?) {
        change({ $0.insertColumn(at: column) }, focus: focus)
    }

    func requestDeleteTable() {
        guard let attachment else { return }
        guard attachment.model.filledCellCount > 1 else {
            endEditing(commit: false)
            host?.deleteTable(attachment)
            return
        }
        showConfirmation()
    }

    private func showConfirmation() {
        confirmation?.removeFromSuperview()
        let label = NSTextField(labelWithString: "Delete this table?")
        label.textColor = .secondaryLabelColor
        let yes = NSButton(title: "Yes", target: self, action: #selector(confirmDelete))
        yes.bezelStyle = .inline
        yes.contentTintColor = .systemRed
        let no = NSButton(title: "No", target: self, action: #selector(cancelDelete))
        no.bezelStyle = .inline
        let stack = NSStackView(views: [label, yes, no])
        stack.spacing = 6
        stack.edgeInsets = NSEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        stack.wantsLayer = true
        stack.layer?.cornerRadius = 6
        stack.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        stack.frame.origin = CGPoint(x: 4, y: 4)
        stack.setFrameSize(stack.fittingSize)
        addSubview(stack)
        confirmation = stack
        Task { @MainActor [weak self, weak stack] in
            try? await Task.sleep(for: .seconds(5))
            guard let self, let stack, confirmation === stack else { return }
            cancelDelete()
        }
    }

    @objc func confirmDelete() {
        cancelDelete()
        guard let attachment else { return }
        endEditing(commit: false)
        host?.deleteTable(attachment)
    }

    @objc func cancelDelete() {
        confirmation?.removeFromSuperview()
        confirmation = nil
    }

    @objc func tableMenuAction(_ sender: NSMenuItem) {
        guard let choice = sender.representedObject as? TableMenu.Choice else { return }
        let index = choice.index
        switch choice.action {
        case .rowAbove: change({ $0.insertRow(at: max(index.row, 1)) }, focus: nil)
        case .rowBelow: change({ $0.insertRow(at: index.row + 1) }, focus: nil)
        case .columnLeft: change({ $0.insertColumn(at: index.column) }, focus: nil)
        case .columnRight: change({ $0.insertColumn(at: index.column + 1) }, focus: nil)
        case .align(let alignment): change({ $0.setAlignment(alignment, column: index.column) }, focus: nil)
        case .deleteRow: change({ $0.deleteRow(index.row) }, focus: nil)
        case .deleteColumn: change({ $0.deleteColumn(index.column) }, focus: nil)
        case .deleteTable: requestDeleteTable()
        }
    }

    var cellEditor: TableCellEditor {
        editor
    }

    var imageTarget: TableImageTarget? {
        guard let editing else { return nil }
        return TableImageTarget(attachment: attachment, cell: editing)
    }

    func insertInline(_ markdown: String) {
        guard let attachment, let editing else { return }
        let alignment = editing.column < model.columns.count ? model.columns[editing.column].alignment : .none
        let range = editor.selectedRange()
        let before = range.location > 0 ? (editor.string as NSString).substring(with: NSRange(location: range.location - 1, length: 1)) : " "
        let inline = TableCellText.inline(markdown) ?? NSAttributedString(string: markdown)
        let text = NSMutableAttributedString()
        if before.allSatisfy(\.isWhitespace) == false {
            text.append(NSAttributedString(string: " ", attributes: editor.typingAttributes))
        }
        text.append(attachment.display(inline, header: editing.row == 0, alignment: alignment))
        guard editor.shouldChangeText(in: range, replacementString: text.string) else { return }
        editor.textStorage?.replaceCharacters(in: range, with: text)
        editor.didChangeText()
        editor.setSelectedRange(NSRange(location: range.location + text.length, length: 0))
        finishCell()
    }

    // MARK: Drop

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        currentLayout.cell(at: convert(sender.draggingLocation, from: nil)) == nil ? [] : .copy
    }

    override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        draggingEntered(sender)
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard let index = currentLayout.cell(at: convert(sender.draggingLocation, from: nil)) else { return false }
        beginEditing(index, caretAtEnd: true)
        return host?.dropIntoCell(sender, target: TableImageTarget(attachment: attachment, cell: index)) ?? false
    }
}
