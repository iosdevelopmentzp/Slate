import AppKit

enum TableMenu {
    enum Action: Equatable {
        case rowAbove
        case rowBelow
        case columnLeft
        case columnRight
        case moveRowUp
        case moveRowDown
        case moveColumnLeft
        case moveColumnRight
        case align(TableAlignment)
        case copyMarkdown
        case copyText
        case convertToText
        case clearCells
        case deleteRow
        case deleteColumn
        case deleteTable
    }

    final class Choice: NSObject {
        let index: TableCellIndex
        let action: Action

        init(index: TableCellIndex, action: Action) {
            self.index = index
            self.action = action
        }
    }

    static func menu(for index: TableCellIndex, model: TableModel, target: AnyObject, selection: TableCellRange? = nil) -> NSMenu {
        let menu = NSMenu()
        let columns = selection?.columns ?? index.column...index.column
        let rows = selection?.rows ?? index.row...index.row
        let alignments = Set(columns.map { $0 < model.columns.count ? model.columns[$0].alignment : .none })
        let alignment = alignments.count == 1 ? alignments.first ?? .none : nil
        let hasBodyRow = rows.contains { $0 > 0 }
        var entries: [(String, Action, Bool, Bool)] = []
        if selection != nil {
            entries += [("Clear Cells", .clearCells, true, false), ("-", .deleteTable, true, false)]
        }
        entries += [
            ("Add Row Above", .rowAbove, index.row > 0, false),
            ("Add Row Below", .rowBelow, true, false),
            ("Add Column Left", .columnLeft, true, false),
            ("Add Column Right", .columnRight, true, false),
            ("-", .deleteTable, true, false),
            ("Move Row Up", .moveRowUp, model.canMoveRows(rows, to: rows.lowerBound - 1), false),
            ("Move Row Down", .moveRowDown, model.canMoveRows(rows, to: rows.upperBound + 2), false),
            ("Move Column Left", .moveColumnLeft, model.canMoveColumns(columns, to: columns.lowerBound - 1), false),
            ("Move Column Right", .moveColumnRight, model.canMoveColumns(columns, to: columns.upperBound + 2), false),
            ("-", .deleteTable, true, false),
            ("Align Left", .align(.left), true, alignment == .left || alignment == .none),
            ("Align Center", .align(.center), true, alignment == .center),
            ("Align Right", .align(.right), true, alignment == .right),
            ("-", .deleteTable, true, false),
            ("Copy Table as Markdown", .copyMarkdown, true, false),
            ("Copy Table as Text", .copyText, true, false),
            ("Convert to Text", .convertToText, true, false),
            ("-", .deleteTable, true, false),
            (rows.count > 1 ? "Delete Rows" : "Delete Row", .deleteRow, hasBodyRow, false),
            (columns.count > 1 ? "Delete Columns" : "Delete Column", .deleteColumn, model.columnCount > columns.count, false),
            ("Delete Table", .deleteTable, true, false),
        ]
        menu.autoenablesItems = false
        for (title, action, enabled, isOn) in entries {
            guard title != "-" else {
                menu.addItem(.separator())
                continue
            }
            let item = NSMenuItem(title: title, action: #selector(TableBlockView.tableMenuAction(_:)), keyEquivalent: "")
            item.target = target
            item.isEnabled = enabled
            item.state = isOn ? .on : .off
            item.representedObject = Choice(index: index, action: action)
            if let key = KeyboardMap.tableKey(for: action) {
                item.keyEquivalent = key
                item.keyEquivalentModifierMask = [.command, .option]
            }
            menu.addItem(item)
        }
        return menu
    }
}
