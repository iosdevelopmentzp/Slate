import AppKit

extension RichTextController {
    static let closedBlocks: Set<BlockKind> = [.monospaced, .raw, .quote]

    func leaveBlockAtEdge(_ selector: Selector) -> Bool {
        let selection = textView.selectedRange()
        guard selection.length == 0, storage.length > 0, activeTable == nil else { return false }
        switch selector {
        case #selector(NSResponder.moveUp(_:)):
            return isOnFirstLine(selection.location) && openLineAbove()
        case #selector(NSResponder.moveLeft(_:)):
            return selection.location == 0 && openLineAbove()
        case #selector(NSResponder.moveDown(_:)):
            return isOnLastLine(selection.location) && openLineBelow()
        case #selector(NSResponder.moveRight(_:)):
            return selection.location == storage.length && openLineBelow()
        default:
            return false
        }
    }

    private func openLineAbove() -> Bool {
        guard Self.closedBlocks.contains(block(at: 0).kind) else { return false }
        replace(NSRange(location: 0, length: 0), with: styled("\n", block: BlockAttributes()), selection: NSRange(location: 0, length: 0))
        return true
    }

    private func openLineBelow() -> Bool {
        let last = block(at: storage.length - 1)
        guard Self.closedBlocks.contains(last.kind), string.character(at: storage.length - 1) != 0x0A else { return false }
        replace(NSRange(location: storage.length, length: 0), with: styled("\n", block: last), selection: NSRange(location: storage.length + 1, length: 0))
        setTailBlock(BlockAttributes())
        return true
    }

    private func isOnFirstLine(_ location: Int) -> Bool {
        lineTop(of: location).map { abs($0 - (lineTop(of: 0) ?? $0)) < 1 } ?? false
    }

    private func isOnLastLine(_ location: Int) -> Bool {
        lineTop(of: location).map { abs($0 - (lineTop(of: storage.length) ?? $0)) < 1 } ?? false
    }

    private func lineTop(of location: Int) -> CGFloat? {
        guard textView.window != nil else { return nil }
        let rect = textView.firstRect(forCharacterRange: NSRange(location: min(location, storage.length), length: 0), actualRange: nil)
        return rect.isNull ? nil : rect.maxY
    }
}
