import AppKit

extension RichTextController {

    func hoverLink(at point: CGPoint?, after delay: Duration = linkHoverDelay) {
        if let point, isOverLinkBar(point) { return }
        let range = point.flatMap(hoverableLink(at:))
        if range == hoveredLink, range == nil || linkHoverTask != nil || linkBar.range == range { return }
        hoveredLink = range
        linkHoverTask?.cancel()
        linkHoverTask = nil
        guard let range else {
            updateLinkBar()
            return
        }
        linkHoverTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: delay)
            guard let self, Task.isCancelled == false else { return }
            linkHoverTask = nil
            showLinkBar(for: range)
        }
    }

    private func isOverLinkBar(_ point: CGPoint) -> Bool {
        linkBar.isHidden == false && linkBar.frame.insetBy(dx: -4, dy: -(LinkBar.gap + 4)).contains(point)
    }

    private func hoverableLink(at point: CGPoint) -> NSRange? {
        guard activeLinkPopover == nil, multiCaret.isActive == false, let index = characterIndex(at: point) else { return nil }
        var range = NSRange(location: 0, length: 0)
        let whole = NSRange(location: 0, length: storage.length)
        if storage.attribute(.slateHref, at: index, longestEffectiveRange: &range, in: whole) != nil { return range }
        guard storage.attribute(.slateReference, at: index, longestEffectiveRange: &range, in: whole) != nil else { return nil }
        return range
    }
}
