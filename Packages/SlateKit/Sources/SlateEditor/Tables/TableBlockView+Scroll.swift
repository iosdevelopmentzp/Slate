import AppKit

extension TableBlockView {
    var contentWidth: CGFloat {
        currentLayout.size.width + TableLayout.handle
    }

    var maxScrollOffset: CGFloat {
        max(contentWidth - frame.width, 0)
    }

    var overflows: Bool {
        maxScrollOffset > 0.5
    }

    func scroll(to offset: CGFloat) {
        let clamped = min(max(offset, 0), maxScrollOffset).rounded()
        scrollOffset = clamped
        guard bounds.origin.x != clamped else { return }
        setBoundsOrigin(NSPoint(x: clamped, y: 0))
        needsDisplay = true
    }

    func reveal(_ index: TableCellIndex) {
        guard overflows else { return }
        let rect = currentLayout.cellRect(index)
        let width = frame.width
        if rect.minX < scrollOffset {
            scroll(to: rect.minX)
        } else if rect.maxX > scrollOffset + width {
            scroll(to: rect.maxX - width)
        }
    }

    override func scrollWheel(with event: NSEvent) {
        let sideways = abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) ? event.scrollingDeltaX : 0
        guard overflows, sideways != 0 else {
            super.scrollWheel(with: event)
            return
        }
        scroll(to: scrollOffset - sideways * (event.hasPreciseScrollingDeltas ? 1 : 8))
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        scroll(to: scrollOffset)
    }

    func scrollerRect(layout: TableLayout) -> CGRect? {
        guard overflows else { return nil }
        let width = frame.width
        let knob = max(width * width / contentWidth, 24)
        let x = scrollOffset + (width - knob) * scrollOffset / maxScrollOffset
        return CGRect(x: x + 2, y: layout.size.height + 1, width: knob - 4, height: 2.5)
    }
}
