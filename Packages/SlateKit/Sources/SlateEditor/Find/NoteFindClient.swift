import AppKit
import Synchronization

final class NoteFindClient: NSObject, NSTextFinderClient {
    weak var controller: RichTextController?
    private let snapshot = Mutex(FindSegments.empty)
    private var isStale = true
    private var remembered: (caret: NSRange, match: NSRange)?

    init(controller: RichTextController) {
        self.controller = controller
    }

    func storageChanged() {
        isStale = true
        guard controller?.scrollView.isFindBarVisible == true else { return }
        refresh()
    }

    func refresh() {
        let made = FindSegments.make(controller?.storage ?? NSTextStorage())
        snapshot.withLock { $0 = made }
        isStale = false
    }

    var segments: FindSegments {
        if isStale {
            refresh()
        }
        return snapshot.withLock { $0 }
    }

    nonisolated var isSelectable: Bool { true }
    nonisolated var allowsMultipleSelection: Bool { false }
    nonisolated var isEditable: Bool { true }

    nonisolated func string(at characterIndex: Int, effectiveRange outRange: NSRangePointer, endsWithSearchBoundary outFlag: UnsafeMutablePointer<ObjCBool>) -> String {
        let segments = snapshot.withLock { $0 }
        outFlag.pointee = true
        guard let item = segments.segment(at: characterIndex) else {
            outRange.pointee = NSRange(location: segments.length, length: 0)
            return ""
        }
        outRange.pointee = item.range
        return item.string
    }

    nonisolated func stringLength() -> Int {
        snapshot.withLock { $0.length }
    }

    var firstSelectedRange: NSRange {
        guard let controller else { return NSRange(location: 0, length: 0) }
        if let table = controller.activeTable, let index = table.editing, table.window?.firstResponder === table.cellEditor,
           let attachment = table.attachment, let location = controller.location(of: attachment),
           let item = segments.items.first(where: { $0.place == .cell(table: location, index: index) }) {
            let selection = table.cellEditor.selectedRange()
            return NSRange(location: item.range.location + selection.location, length: selection.length)
        }
        let selection = controller.textView.selectedRange()
        if let remembered, remembered.caret == selection {
            return remembered.match
        }
        let start = segments.virtualLocation(ofStorage: selection.location)
        let end = segments.virtualLocation(ofStorage: NSMaxRange(selection))
        return NSRange(location: start, length: max(end - start, 0))
    }

    var selectedRanges: [NSValue] {
        get { [NSValue(range: firstSelectedRange)] }
        set {
            guard let controller, let range = newValue.first?.rangeValue, let (item, local) = segments.local(range) else { return }
            controller.activeTable?.endEditing()
            switch item.place {
            case .text(let text):
                remembered = nil
                controller.textView.setSelectedRange(NSRange(location: text.location + local.location, length: local.length))
            case .cell(let table, let index):
                let caret = NSRange(location: table, length: 0)
                controller.textView.setSelectedRange(caret)
                remembered = (caret, range)
                Task { @MainActor [weak self] in
                    guard let self, let view = tableView(at: table) else { return }
                    view.select(local, in: index)
                }
            }
        }
    }

    func scrollRangeToVisible(_ range: NSRange) {
        guard let controller, let (item, local) = segments.local(range) else { return }
        switch item.place {
        case .text(let text):
            controller.textView.scrollRangeToVisible(NSRange(location: text.location + local.location, length: local.length))
        case .cell(let table, let index):
            controller.textView.scrollRangeToVisible(NSRange(location: table, length: 1))
            controller.textView.textLayoutManager?.textViewportLayoutController.layoutViewport()
            guard let view = tableView(at: table) else { return }
            view.reveal(index)
            view.scrollToVisible(view.currentLayout.cellRect(index))
        }
    }

    func contentView(at index: Int, effectiveCharacterRange outRange: NSRangePointer) -> NSView {
        guard let controller else { return NSView() }
        guard let item = segments.segment(at: index) else {
            outRange.pointee = NSRange(location: 0, length: segments.length)
            return controller.textView
        }
        outRange.pointee = item.group
        if case .cell(let table, _) = item.place, let view = tableView(at: table) {
            return view
        }
        return controller.textView
    }

    func rects(forCharacterRange range: NSRange) -> [NSValue]? {
        guard let controller, let (item, local) = segments.local(range) else { return nil }
        switch item.place {
        case .text(let text):
            guard let layout = controller.textView.textLayoutManager else { return nil }
            let origin = controller.textView.textContainerOrigin
            let storageRange = NSRange(location: text.location + local.location, length: local.length)
            return TextSegmentRects.rects(of: storageRange, in: layout).map { NSValue(rect: $0.offsetBy(dx: origin.x, dy: origin.y)) }
        case .cell(let table, let index):
            guard let view = tableView(at: table), let attachment = view.attachment else { return nil }
            let frame = view.currentLayout.textRect(index)
            return TextSegmentRects.rects(of: local, in: attachment.text(index), width: frame.width).map { NSValue(rect: $0.offsetBy(dx: frame.minX, dy: frame.minY)) }
        }
    }

    func drawCharacters(in range: NSRange, forContentView view: NSView) {
        guard let controller, let (item, local) = segments.local(range) else { return }
        switch item.place {
        case .text(let text):
            guard let layout = controller.textView.textLayoutManager else { return }
            let storageRange = NSRange(location: text.location + local.location, length: local.length)
            Self.draw(TextSegmentRects.pieces(of: storageRange, in: layout), of: controller.storage, at: controller.textView.textContainerOrigin)
        case .cell(let table, let index):
            guard let view = tableView(at: table), let attachment = view.attachment else { return }
            let frame = view.currentLayout.textRect(index)
            let text = attachment.text(index)
            Self.draw(TextSegmentRects.pieces(of: local, in: text, width: frame.width), of: text, at: frame.origin)
        }
    }

    private static func draw(_ pieces: [(range: NSRange, frame: CGRect, baseline: CGFloat)], of text: NSAttributedString, at origin: CGPoint) {
        for piece in pieces where piece.range.length > 0 && NSMaxRange(piece.range) <= text.length {
            let line = NSMutableAttributedString(attributedString: text.attributedSubstring(from: piece.range))
            let whole = NSRange(location: 0, length: line.length)
            line.removeAttribute(.paragraphStyle, range: whole)
            line.removeAttribute(.backgroundColor, range: whole)
            line.addAttribute(.foregroundColor, value: NSColor.black, range: whole)
            let font = line.attribute(.font, at: 0, effectiveRange: nil) as? NSFont ?? .systemFont(ofSize: NSFont.systemFontSize)
            line.draw(at: CGPoint(x: origin.x + piece.frame.minX, y: origin.y + piece.frame.minY + piece.baseline - font.ascender))
        }
    }

    var visibleCharacterRanges: [NSValue] {
        [NSValue(range: NSRange(location: 0, length: segments.length))]
    }

    func replaceCharacters(in range: NSRange, with string: String) {
        guard let controller, let (item, local) = segments.local(range) else { return }
        switch item.place {
        case .text(let text):
            let target = NSRange(location: text.location + local.location, length: local.length)
            let attributes = controller.storage.attributes(at: min(target.location, max(controller.storage.length - 1, 0)), effectiveRange: nil)
            controller.replace(target, with: NSAttributedString(string: string, attributes: attributes), selection: NSRange(location: target.location + (string as NSString).length, length: 0))
        case .cell(let table, let index):
            guard let attachment = controller.storage.attribute(.attachment, at: table, effectiveRange: nil) as? TableAttachment else { return }
            attachment.loadedView?.endEditing()
            let text = NSMutableAttributedString(attributedString: attachment.text(index))
            let attributes = text.length > 0 ? text.attributes(at: min(local.location, text.length - 1), effectiveRange: nil) : [:]
            text.replaceCharacters(in: local, with: NSAttributedString(string: string, attributes: attributes))
            var model = attachment.model
            model.setCell(index, markdown: TableCellText.markdown(of: text))
            controller.tableDidChange(attachment, model: model, before: attachment.block.model)
        }
        refresh()
    }

    private func tableView(at location: Int) -> TableBlockView? {
        guard let controller, location < controller.storage.length,
              let attachment = controller.storage.attribute(.attachment, at: location, effectiveRange: nil) as? TableAttachment,
              let view = attachment.loadedView, view.window != nil
        else { return nil }
        return view
    }
}
