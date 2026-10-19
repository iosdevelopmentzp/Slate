import AppKit

extension RichTextController {
    static let caretMoves: Set<Selector> = [
        #selector(NSResponder.moveLeft(_:)),
        #selector(NSResponder.moveRight(_:)),
        #selector(NSResponder.moveUp(_:)),
        #selector(NSResponder.moveDown(_:)),
        #selector(NSResponder.moveBackward(_:)),
        #selector(NSResponder.moveForward(_:)),
        #selector(NSResponder.moveWordLeft(_:)),
        #selector(NSResponder.moveWordRight(_:)),
        #selector(NSResponder.moveWordBackward(_:)),
        #selector(NSResponder.moveWordForward(_:)),
        #selector(NSResponder.moveToLeftEndOfLine(_:)),
        #selector(NSResponder.moveToRightEndOfLine(_:)),
        #selector(NSResponder.moveToBeginningOfLine(_:)),
        #selector(NSResponder.moveToEndOfLine(_:)),
        #selector(NSResponder.moveToBeginningOfParagraph(_:)),
        #selector(NSResponder.moveToEndOfParagraph(_:)),
    ]

    var caretLocations: [Int] {
        multiCaret.extras + [textView.selectedRange().location]
    }

    func addCaret(_ direction: CaretDirection) -> Bool {
        guard activeTable == nil, textView.hasMarkedText() == false else { return false }
        let all = caretLocations.sorted()
        guard let anchor = direction == .up ? all.first : all.last else { return false }
        guard let next = verticalNeighbour(of: anchor, direction: direction), all.contains(next) == false else { return true }
        var positions = caretLocations
        positions.insert(next, at: positions.count - 1)
        setCarets(positions, primary: positions.count - 1)
        textView.scrollRangeToVisible(NSRange(location: next, length: 0))
        return true
    }

    func dropExtraCarets() {
        guard multiCaret.isActive else { return }
        multiCaret.extras = []
        multiCaret.overlay.show([])
    }

    func handleAtCarets(_ selector: Selector) -> Bool? {
        switch selector {
        case #selector(NSResponder.cancelOperation(_:)):
            dropExtraCarets()
            return true
        case #selector(NSResponder.deleteBackward(_:)):
            editAtCarets { self.deletion(before: $0) }
            return true
        case #selector(NSResponder.deleteForward(_:)):
            editAtCarets { self.deletion(after: $0) }
            return true
        case let move where Self.caretMoves.contains(move):
            let positions = caretLocations.map { moved($0, by: move) }
            setCarets(positions, primary: positions.count - 1)
            return true
        default:
            dropExtraCarets()
            return nil
        }
    }

    func typeAtCarets(_ text: String) -> Bool {
        guard text.contains(where: \.isNewline) == false else {
            dropExtraCarets()
            return false
        }
        editAtCarets { location in
            guard self.block(at: location).kind.isAttachment == false else { return nil }
            return (NSRange(location: location, length: 0), NSAttributedString(string: text, attributes: self.caretAttributes(at: location)))
        }
        return true
    }

    func refreshCaretOverlay() {
        guard multiCaret.isActive else { return }
        multiCaret.overlay.color = textView.insertionPointColor
        if multiCaret.overlay.superview !== textView {
            multiCaret.overlay.frame = textView.bounds
            multiCaret.overlay.autoresizingMask = [.width, .height]
            textView.addSubview(multiCaret.overlay)
        }
        multiCaret.overlay.show(multiCaret.extras.compactMap(caretRect))
    }

    private func editAtCarets(_ edit: (Int) -> (NSRange, NSAttributedString)?) {
        var positions = caretLocations
        let order = positions.indices.sorted { positions[$0] > positions[$1] }
        multiCaret.isApplying = true
        textView.breakUndoCoalescing()
        undoManager.beginUndoGrouping()
        for index in order {
            guard let (range, text) = edit(positions[index]) else { continue }
            let before = storage.length
            replace(range, with: text, selection: nil)
            guard storage.length - before == text.length - range.length else { continue }
            positions = MultiCaret.shifted(positions, editing: index, range: range, insertedLength: text.length)
        }
        undoManager.endUndoGrouping()
        multiCaret.isApplying = false
        setCarets(positions, primary: positions.count - 1)
    }

    private func setCarets(_ positions: [Int], primary: Int) {
        let merged = MultiCaret.merged(positions, primary: primary, limit: storage.length)
        multiCaret.isApplying = true
        multiCaret.extras = merged.extras
        textView.setSelectedRange(NSRange(location: merged.primary, length: 0))
        multiCaret.isApplying = false
        if multiCaret.isActive {
            refreshCaretOverlay()
        } else {
            multiCaret.overlay.show([])
        }
    }

    private func deletion(before location: Int) -> (NSRange, NSAttributedString)? {
        guard location > 0, location <= storage.length else { return nil }
        let range = string.rangeOfComposedCharacterSequence(at: location - 1)
        return isDeletable(range) ? (range, NSAttributedString()) : nil
    }

    private func deletion(after location: Int) -> (NSRange, NSAttributedString)? {
        guard location < storage.length else { return nil }
        let range = string.rangeOfComposedCharacterSequence(at: location)
        return isDeletable(range) ? (range, NSAttributedString()) : nil
    }

    private func isDeletable(_ range: NSRange) -> Bool {
        let text = string.substring(with: range)
        return text != "\n" && text != RichText.attachmentString && block(at: range.location).kind.isAttachment == false
    }

    private func caretAttributes(at location: Int) -> [NSAttributedString.Key: Any] {
        var inline: InlineStyle = []
        if location > 0, storage.length > 0, isEmptyTail(location) == false {
            let index = min(location - 1, storage.length - 1)
            if string.character(at: index) != 0x0A {
                inline = InlineStyle(rawValue: storage.attribute(.slateInline, at: index, effectiveRange: nil) as? Int ?? 0)
            }
        }
        return styler.attributes(block: block(at: location), inline: inline, href: nil)
    }

    private func moved(_ location: Int, by selector: Selector) -> Int {
        let saved = textView.selectedRange()
        let wasInternal = isEditingInternally
        isEditingInternally = true
        textView.setSelectedRange(NSRange(location: location, length: 0))
        textView.perform(selector, with: nil)
        let result = textView.selectedRange().location
        textView.setSelectedRange(saved)
        isEditingInternally = wasInternal
        return result
    }

    private func verticalNeighbour(of location: Int, direction: CaretDirection) -> Int? {
        guard let start = caretRect(location) else { return nil }
        let selector = direction == .up ? #selector(NSResponder.moveUp(_:)) : #selector(NSResponder.moveDown(_:))
        var current = location
        for _ in 0..<20 {
            let next = moved(current, by: selector)
            guard next != current, let rect = caretRect(next) else { return nil }
            current = next
            let onAnotherLine = direction == .up ? rect.midY < start.minY : rect.midY > start.maxY
            guard onAnotherLine else { continue }
            guard block(at: current).kind.isAttachment == false else { continue }
            return aligned(current, lineRect: rect, x: start.minX)
        }
        return nil
    }

    private func aligned(_ location: Int, lineRect: NSRect, x: CGFloat) -> Int {
        let index = textView.characterIndexForInsertion(at: NSPoint(x: x, y: lineRect.midY))
        guard index != NSNotFound, index <= storage.length, paragraphRange(at: index) == paragraphRange(at: location) else { return location }
        return index
    }

    private func caretRect(_ location: Int) -> NSRect? {
        guard let window = textView.window else { return nil }
        let screen = textView.firstRect(forCharacterRange: NSRange(location: min(location, storage.length), length: 0), actualRange: nil)
        guard screen.height > 0 else { return nil }
        return textView.convert(window.convertFromScreen(screen), from: nil)
    }
}
