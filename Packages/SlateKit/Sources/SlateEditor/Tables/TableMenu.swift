import AppKit

enum TableMenu {
    enum Action: Equatable {
        case rowAbove
        case rowBelow
        case columnLeft
        case columnRight
        case align(TableAlignment)
        case copyMarkdown
        case copyText
        case convertToText
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

    static func menu(for index: TableCellIndex, model: TableModel, target: AnyObject) -> NSMenu {
        let menu = NSMenu()
        let alignment = index.column < model.columns.count ? model.columns[index.column].alignment : .none
        let entries: [(String, Action, Bool, Bool)] = [
            ("Add Row Above", .rowAbove, index.row > 0, false),
            ("Add Row Below", .rowBelow, true, false),
            ("Add Column Left", .columnLeft, true, false),
            ("Add Column Right", .columnRight, true, false),
            ("-", .deleteTable, true, false),
            ("Align Left", .align(.left), true, alignment == .left || alignment == .none),
            ("Align Center", .align(.center), true, alignment == .center),
            ("Align Right", .align(.right), true, alignment == .right),
            ("-", .deleteTable, true, false),
            ("Copy Table as Markdown", .copyMarkdown, true, false),
            ("Copy Table as Text", .copyText, true, false),
            ("Convert to Text", .convertToText, true, false),
            ("-", .deleteTable, true, false),
            ("Delete Row", .deleteRow, index.row > 0, false),
            ("Delete Column", .deleteColumn, model.columnCount > 1, false),
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
            menu.addItem(item)
        }
        return menu
    }
}
