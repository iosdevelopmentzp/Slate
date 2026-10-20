import AppKit

extension RichTextController {

    func toggleSection(at heading: Int) {
        if foldedHeadings.contains(heading) {
            unfold([heading])
        } else {
            fold([heading])
        }
    }

    func collapseSection() {
        guard let section = HeadingSection.containing(textView.selectedRange().location, in: storage) else { return }
        fold([section.heading])
    }

    func expandSection() {
        guard let section = HeadingSection.containing(textView.selectedRange().location, in: storage) else { return }
        unfold(foldedHeadings.filter { $0 == section.heading || NSLocationInRange($0, section.body) })
    }

    func collapseAllSections() {
        fold(Set(HeadingSection.all(in: storage).map(\.heading)))
    }

    func expandAllSections() {
        unfold(foldedHeadings)
    }

    func apply(collapsedSections keys: [String]) {
        guard keys != syncedSections else { return }
        syncedSections = keys
        let headings = SectionKeys.headings(for: keys, in: storage)
        guard headings != foldedHeadings else { return }
        foldedHeadings = headings
        updateHiddenSections()
        needsFoldLayout = false
        relayoutDocument()
        keepCaretVisible()
    }

    func reveal(_ location: Int) {
        let covering = foldedHeadings.filter { heading in
            HeadingSection.at(heading, in: storage).map { NSLocationInRange(location, $0.body) } ?? false
        }
        unfold(covering)
    }

    func isHidden(_ location: Int) -> Bool {
        hiddenSections.contains { NSLocationInRange(location, $0) }
    }

    func foldMark(at location: Int) -> RichLayoutFragment.Fold? {
        if foldedHeadings.contains(location) { return .closed }
        return hoveredHeading == location ? .open : nil
    }

    func hoverHeading(at point: CGPoint?) {
        let heading = point.flatMap(foldableHeading(at:))
        guard heading != hoveredHeading else { return }
        let previous = hoveredHeading
        hoveredHeading = heading
        for location in [previous, heading].compactMap({ $0 }) {
            relayoutParagraph(at: location)
        }
    }

    func foldHit(at point: CGPoint) -> Int? {
        guard let layout = textView.textLayoutManager else { return nil }
        let origin = textView.textContainerOrigin
        let local = CGPoint(x: point.x - origin.x, y: point.y - origin.y)
        guard let fragment = layout.textLayoutFragment(for: CGPoint(x: 1, y: local.y)) as? RichLayoutFragment, fragment.fold != nil else { return nil }
        let frame = fragment.layoutFragmentFrame
        let mark = fragment.foldRect.offsetBy(dx: frame.minX, dy: frame.minY).insetBy(dx: -5, dy: -5)
        guard mark.contains(local) else { return nil }
        return layout.offset(from: layout.documentRange.location, to: fragment.rangeInElement.location)
    }

    func visibleSelection(from old: NSRange, to new: NSRange) -> NSRange {
        guard hiddenSections.isEmpty == false, let section = hiddenSection(containing: new.location) else { return new }
        if new.length > 0 {
            if NSMaxRange(new) <= NSMaxRange(section.body) { reveal(new.location) }
            return new
        }
        if new.location >= old.location, NSMaxRange(section.body) < storage.length {
            return NSRange(location: NSMaxRange(section.body), length: 0)
        }
        return NSRange(location: NSMaxRange(contentRange(of: paragraphRange(at: section.heading))), length: 0)
    }

    func unfoldSections(touching range: NSRange, replacement: String?) {
        guard foldedHeadings.isEmpty == false else { return }
        let breaksLine = replacement?.contains("\n") == true
        let touched = foldedHeadings.filter { heading in
            guard let section = HeadingSection.at(heading, in: storage) else { return false }
            let headingEnd = NSMaxRange(contentRange(of: paragraphRange(at: heading)))
            let span = NSRange(location: headingEnd, length: NSMaxRange(section.body) - headingEnd)
            if breaksLine, range.location >= heading, range.location <= NSMaxRange(span) { return true }
            if range.length == 0 { return range.location > span.location && range.location < NSMaxRange(span) }
            return NSIntersectionRange(range, span).length > 0
        }
        guard touched.isEmpty == false else { return }
        foldedHeadings.subtract(touched)
        updateHiddenSections()
        needsFoldLayout = true
    }

    func shiftFolds(editedRange: NSRange, delta: Int) {
        hoveredHeading = nil
        guard foldedHeadings.isEmpty == false else { return }
        let oldEnd = NSMaxRange(editedRange) - delta
        foldedHeadings = Set(foldedHeadings.compactMap { heading -> Int? in
            if heading < editedRange.location { return heading }
            if heading == editedRange.location, oldEnd == heading { return heading }
            if heading >= oldEnd { return heading + delta }
            return heading == editedRange.location ? heading : nil
        })
        if updateHiddenSections() { needsFoldLayout = true }
    }

    func refreshFoldsAfterEdit() {
        guard foldedHeadings.isEmpty == false || needsFoldLayout else { return }
        if updateHiddenSections() { needsFoldLayout = true }
        reportSections()
        guard needsFoldLayout else { return }
        needsFoldLayout = false
        relayoutDocument()
    }

    private func fold(_ headings: Set<Int>) {
        let foldable = headings.filter { (HeadingSection.at($0, in: storage)?.body.length ?? 0) > 0 }
        guard foldable.isSubset(of: foldedHeadings) == false else { return }
        foldedHeadings.formUnion(foldable)
        foldsChanged()
    }

    private func unfold(_ headings: Set<Int>) {
        guard headings.isDisjoint(with: foldedHeadings) == false else { return }
        foldedHeadings.subtract(headings)
        foldsChanged()
    }

    private func foldsChanged() {
        updateHiddenSections()
        needsFoldLayout = false
        relayoutDocument()
        keepCaretVisible()
        reportSections()
    }

    private func reportSections() {
        let keys = SectionKeys.keys(for: foldedHeadings, in: storage)
        guard keys != syncedSections ?? [] else { return }
        syncedSections = keys
        handlers.collapsedSections(keys)
    }

    private func keepCaretVisible() {
        let selection = textView.selectedRange()
        if let section = hiddenSection(containing: selection.location) {
            textView.setSelectedRange(NSRange(location: NSMaxRange(contentRange(of: paragraphRange(at: section.heading))), length: 0))
        }
    }

    @discardableResult
    private func updateHiddenSections() -> Bool {
        let sections = foldedHeadings.compactMap { HeadingSection.at($0, in: storage) }.filter { $0.body.length > 0 }
        let kept = Set(sections.map(\.heading))
        let dropped = kept != foldedHeadings
        foldedHeadings = kept
        hiddenSections = sections.map(\.body).sorted { $0.location < $1.location }
        return dropped
    }

    private func hiddenSection(containing location: Int) -> HeadingSection? {
        foldedHeadings.sorted()
            .compactMap { HeadingSection.at($0, in: storage) }
            .first { NSLocationInRange(location, $0.body) }
    }

    private func foldableHeading(at point: CGPoint) -> Int? {
        guard let layout = textView.textLayoutManager else { return nil }
        let origin = textView.textContainerOrigin
        let local = CGPoint(x: point.x - origin.x, y: point.y - origin.y)
        guard let fragment = layout.textLayoutFragment(for: CGPoint(x: 1, y: local.y)), fragment.layoutFragmentFrame.minY <= local.y, fragment.layoutFragmentFrame.maxY > local.y else { return nil }
        let location = layout.offset(from: layout.documentRange.location, to: fragment.rangeInElement.location)
        guard let section = HeadingSection.at(location, in: storage), section.body.length > 0 else { return nil }
        return location
    }

    private func relayoutParagraph(at location: Int) {
        guard location < storage.length, let layout = textView.textLayoutManager,
              let content = layout.textContentManager,
              let start = content.location(content.documentRange.location, offsetBy: location),
              let end = content.location(start, offsetBy: paragraphRange(at: location).length),
              let range = NSTextRange(location: start, end: end)
        else { return }
        (layout.textLayoutFragment(for: start) as? RichLayoutFragment)?.fold = foldMark(at: location)
        layout.invalidateLayout(for: range)
        layout.textViewportLayoutController.layoutViewport()
    }

    private func relayoutDocument() {
        guard let layout = textView.textLayoutManager else { return }
        layout.enumerateTextLayoutFragments(from: layout.documentRange.location) { fragment in
            let location = layout.offset(from: layout.documentRange.location, to: fragment.rangeInElement.location)
            if let fragment = fragment as? RichLayoutFragment, block(at: location).kind.headingLevel != nil {
                fragment.fold = foldMark(at: location)
            }
            return true
        }
        layout.invalidateLayout(for: layout.documentRange)
        layout.textViewportLayoutController.layoutViewport()
        textView.needsDisplay = true
    }
}
