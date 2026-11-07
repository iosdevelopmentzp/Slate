import AppKit

extension RichTextController {

    func hoverCode(at point: CGPoint?) {
        guard let point, let layout = textView.textLayoutManager else {
            codeCopyButton.hide()
            return
        }
        let origin = textView.textContainerOrigin
        let local = CGPoint(x: point.x - origin.x, y: point.y - origin.y)
        guard let fragment = layout.textLayoutFragment(for: local) as? RichLayoutFragment else {
            codeCopyButton.hide()
            return
        }
        let location = layout.offset(from: layout.documentRange.location, to: fragment.rangeInElement.location)
        let frame = fragment.layoutFragmentFrame
        let block = fragment.blockRect.offsetBy(dx: frame.minX + origin.x, dy: frame.minY + origin.y)
        guard location < storage.length, self.block(at: location).kind == .monospaced, block.contains(point) else {
            codeCopyButton.hide()
            return
        }
        let label = fragment.languageLabelRect
        let right = label.isEmpty ? block.maxX - 6 : label.minX + frame.minX + origin.x - CodeCopyButton.gap
        let top = label.isEmpty ? block.minY + 4 : label.midY + frame.minY + origin.y - CodeCopyButton.side / 2
        codeCopyButton.show(location: location, at: CGPoint(x: right - CodeCopyButton.side, y: top), in: textView)
    }

    func codeText(at location: Int) -> String? {
        guard location < storage.length, block(at: location).kind == .monospaced else { return nil }
        let content = contentRange(of: paragraphRange(at: location))
        return string.substring(with: content).replacingOccurrences(of: RichText.lineBreakString, with: "\n")
    }
}
