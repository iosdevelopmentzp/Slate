import AppKit

extension RichTextController {

    func outlineMenu() -> NSMenu {
        let menu = NSMenu(title: "Headings")
        let items = OutlineItem.items(in: storage)
        guard items.isEmpty == false else {
            let empty = NSMenuItem(title: "No headings in this note", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
            return menu
        }
        let current = OutlineItem.current(in: items, at: textView.selectedRange().location)
        let lowest = items.map(\.level).min() ?? 0
        for item in items {
            let entry = NSMenuItem(title: item.title, action: #selector(RichTextView.slateJumpToHeading(_:)), keyEquivalent: "")
            entry.target = textView
            entry.tag = item.location
            entry.indentationLevel = item.level - lowest
            entry.state = item == current ? .on : .off
            menu.addItem(entry)
        }
        return menu
    }

    func showOutline() {
        let visible = textView.visibleRect
        let caret = textView.selectedRange()
        var point = CGPoint(x: visible.maxX - 260, y: visible.minY + 8)
        if let window = textView.window, NSApp.currentEvent?.type == .keyDown {
            let screen = textView.firstRect(forCharacterRange: NSRange(location: caret.location, length: 0), actualRange: nil)
            let rect = textView.convert(window.convertFromScreen(screen), from: nil)
            if visible.contains(rect.origin) { point = CGPoint(x: rect.minX, y: rect.maxY + 4) }
        }
        outlineMenu().popUp(positioning: nil, at: point, in: textView)
    }

    func jumpToHeading(at location: Int) {
        guard location < storage.length else { return }
        let paragraph = contentRange(of: paragraphRange(at: location))
        textView.window?.makeFirstResponder(textView)
        textView.setSelectedRange(NSRange(location: paragraph.location, length: 0))
        if let layout = textView.textLayoutManager, let start = layout.location(layout.documentRange.location, offsetBy: paragraph.location) {
            layout.ensureLayout(for: NSTextRange(location: start))
            if let fragment = layout.textLayoutFragment(for: start) {
                let top = fragment.layoutFragmentFrame.minY + textView.textContainerOrigin.y - 16
                textView.scroll(CGPoint(x: 0, y: max(top, 0)))
            }
        }
        textView.showFindIndicator(for: paragraph)
    }
}
