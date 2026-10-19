import AppKit

extension TableBlockView {

    // MARK: Drawing

    func drawGrips(layout: TableLayout, colors: EditorColors) {
        if let grab {
            drawGrab(grab, layout: layout)
            return
        }
        guard let hoverPoint else { return }
        let hit = layout.grip(at: hoverPoint)
        for grip in layout.grips(near: hoverPoint) {
            let rect = layout.rect(of: grip)
            if grip.isInsertion {
                drawInsertion(grip, in: rect, layout: layout)
            } else {
                (grip == hit ? NSColor.controlAccentColor : colors.secondaryText.withAlphaComponent(0.45)).setFill()
                NSBezierPath(roundedRect: rect, xRadius: 2.5, yRadius: 2.5).fill()
            }
        }
    }

    private func drawInsertion(_ grip: TableGrip, in rect: CGRect, layout: TableLayout) {
        NSColor.controlAccentColor.setFill()
        switch grip {
        case .insertRow(let row):
            CGRect(x: rect.maxX, y: layout.rowTop(row) - 1, width: layout.size.width - rect.maxX, height: 2).fill()
        case .insertColumn(let column):
            CGRect(x: layout.columnLeft(column) - 1, y: rect.maxY, width: 2, height: layout.size.height - rect.maxY).fill()
        case .row, .column:
            break
        }
        NSBezierPath(ovalIn: rect).fill()
        NSColor.white.setFill()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        CGRect(x: center.x - 3.5, y: center.y - 0.75, width: 7, height: 1.5).fill()
        CGRect(x: center.x - 0.75, y: center.y - 3.5, width: 1.5, height: 7).fill()
    }

    private func drawGrab(_ grab: TableGrab, layout: TableLayout) {
        let moving: CGRect
        switch grab.grip {
        case .row(let row):
            let cell = layout.cellRect(TableCellIndex(row: row, column: 0))
            moving = CGRect(x: 0, y: cell.minY, width: layout.size.width, height: cell.height)
        case .column(let column):
            let cell = layout.cellRect(TableCellIndex(row: 0, column: column))
            moving = CGRect(x: cell.minX, y: 0, width: cell.width, height: layout.size.height)
        case .insertRow, .insertColumn:
            return
        }
        NSColor.controlAccentColor.withAlphaComponent(0.12).setFill()
        moving.fill()
        guard let target = grab.target else { return }
        NSColor.controlAccentColor.setFill()
        switch grab.grip {
        case .row:
            CGRect(x: 0, y: layout.rowTop(target) - 1.5, width: layout.size.width, height: 3).fill()
        case .column:
            CGRect(x: layout.columnLeft(target) - 1.5, y: 0, width: 3, height: layout.size.height).fill()
        case .insertRow, .insertColumn:
            break
        }
    }

    // MARK: Mouse

    func pressGrip(_ grip: TableGrip, at point: CGPoint) {
        switch grip {
        case .insertRow(let row):
            addRow(at: row, focus: TableCellIndex(row: row, column: 0))
        case .insertColumn(let column):
            addColumn(at: column, focus: TableCellIndex(row: 0, column: column))
        case .row, .column:
            grab = TableGrab(grip: grip, start: point, target: nil)
            needsDisplay = true
        }
    }

    func dragGrip(to point: CGPoint) {
        guard var grab, let model = attachment?.model else { return }
        guard grab.isDragging || hypot(point.x - grab.start.x, point.y - grab.start.y) > 3 else { return }
        grab.isDragging = true
        let layout = currentLayout
        switch grab.grip {
        case .row(let row):
            let target = layout.rowInsertion(atY: point.y)
            grab.target = model.canMoveRows(row...row, to: target) ? target : nil
        case .column(let column):
            let target = layout.columnInsertion(atX: point.x)
            grab.target = model.canMoveColumns(column...column, to: target) ? target : nil
        case .insertRow, .insertColumn:
            break
        }
        self.grab = grab
        needsDisplay = true
    }

    func releaseGrip() {
        guard let grab else { return }
        self.grab = nil
        needsDisplay = true
        switch grab.grip {
        case .row(let row):
            if let target = grab.target {
                moveRows(row...row, to: target)
            } else if grab.isDragging == false {
                showGripMenu(TableCellRange(anchor: TableCellIndex(row: row, column: 0), head: TableCellIndex(row: row, column: (attachment?.model.columnCount ?? 1) - 1)), at: grab.grip)
            }
        case .column(let column):
            if let target = grab.target {
                moveColumns(column...column, to: target)
            } else if grab.isDragging == false {
                showGripMenu(TableCellRange(anchor: TableCellIndex(row: 0, column: column), head: TableCellIndex(row: (attachment?.model.rowCount ?? 1) - 1, column: column)), at: grab.grip)
            }
        case .insertRow, .insertColumn:
            break
        }
    }

    private func showGripMenu(_ range: TableCellRange, at grip: TableGrip) {
        guard let model = attachment?.model else { return }
        selectCells(range)
        let rect = currentLayout.rect(of: grip)
        TableMenu.menu(for: range.topLeft, model: model, target: self, selection: range)
            .popUp(positioning: nil, at: CGPoint(x: rect.minX, y: rect.maxY + 2), in: self)
    }

    // MARK: Moves

    func move(_ action: TableMenu.Action, at index: TableCellIndex, selection: TableCellRange?) {
        let rows = selection?.rows ?? index.row...index.row
        let columns = selection?.columns ?? index.column...index.column
        switch action {
        case .moveRowUp: moveRows(rows, to: rows.lowerBound - 1)
        case .moveRowDown: moveRows(rows, to: rows.upperBound + 2)
        case .moveColumnLeft: moveColumns(columns, to: columns.lowerBound - 1)
        case .moveColumnRight: moveColumns(columns, to: columns.upperBound + 2)
        default: break
        }
    }

    func moveRows(_ rows: ClosedRange<Int>, to destination: Int) {
        guard let model = attachment?.model, model.canMoveRows(rows, to: destination) else { return }
        let map = { (index: TableCellIndex) in
            TableCellIndex(row: TableModel.position(of: index.row, moving: rows, to: destination), column: index.column)
        }
        moveCells({ $0.moveRows(rows, to: destination) }, map: map)
    }

    func moveColumns(_ columns: ClosedRange<Int>, to destination: Int) {
        guard let model = attachment?.model, model.canMoveColumns(columns, to: destination) else { return }
        let map = { (index: TableCellIndex) in
            TableCellIndex(row: index.row, column: TableModel.position(of: index.column, moving: columns, to: destination))
        }
        moveCells({ $0.moveColumns(columns, to: destination) }, map: map)
    }

    private func moveCells(_ transform: (inout TableModel) -> Void, map: (TableCellIndex) -> TableCellIndex) {
        let selection = cellSelection
        let caret = editing == nil ? nil : cellEditor.selectedRange()
        let focus = editing.map(map)
        change(transform, focus: focus)
        if let selection {
            selectCells(TableCellRange(anchor: map(selection.anchor), head: map(selection.head)))
        } else if let caret, let focus, editing == focus {
            select(caret, in: focus)
        }
    }
}
