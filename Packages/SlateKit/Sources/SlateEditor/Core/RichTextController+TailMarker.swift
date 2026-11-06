import AppKit

extension RichTextController {
    func refreshTailMarker() {
        let decoration = tailDecoration
        guard decoration != .none, let line = tailLineRect() else {
            tailMarker.hide()
            return
        }
        let font = styler.font(for: emptyTailBlock.kind, inline: [])
        let rect = ListMarker.rect(lineStart: line.minX, baseline: line.maxY + font.descender, fontSize: font.pointSize)
        if tailMarker.superview !== textView {
            textView.addSubview(tailMarker)
        }
        tailMarker.show(decoration, at: rect, fontSize: font.pointSize, colors: styler.configuration.colors)
    }

    var tailDecoration: ParagraphDecoration {
        guard emptyTailBlock.kind.isList, isEmptyTail(storage.length) else { return .none }
        var attributes = emptyTailBlock.attributes
        if emptyTailBlock.kind == .numbered {
            attributes[.slateListNumber] = tailNumber(level: emptyTailBlock.indent)
        }
        return ParagraphDecoration.of(attributes)
    }

    private func tailNumber(level: Int) -> Int {
        var start = storage.length
        while start > 0 {
            let paragraph = paragraphRange(at: start - 1)
            let attributes = storage.attributes(at: paragraph.location, effectiveRange: nil)
            let above = BlockAttributes(attributes)
            guard above.continuesList else { return 1 }
            if above.kind.isList, above.indent <= level {
                guard above.indent == level, above.kind == .numbered else { return 1 }
                return (attributes[.slateListNumber] as? Int ?? 1) + 1
            }
            start = paragraph.location
        }
        return 1
    }

    private func tailLineRect() -> CGRect? {
        guard let layout = textView.textLayoutManager else { return nil }
        let end = layout.documentRange.endLocation
        layout.ensureLayout(for: NSTextRange(location: end))
        var line: CGRect?
        layout.enumerateTextSegments(in: NSTextRange(location: end), type: .standard, options: []) { _, rect, _, _ in
            line = rect
            return false
        }
        guard let line, line.height > 0 else { return nil }
        let origin = textView.textContainerOrigin
        return line.offsetBy(dx: origin.x, dy: origin.y)
    }
}
