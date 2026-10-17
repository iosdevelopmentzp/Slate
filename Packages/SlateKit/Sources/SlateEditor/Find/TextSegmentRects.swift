import AppKit

enum TextSegmentRects {
    static func rects(of range: NSRange, in layout: NSTextLayoutManager) -> [CGRect] {
        guard let content = layout.textContentManager,
              let start = content.location(content.documentRange.location, offsetBy: range.location),
              let end = content.location(start, offsetBy: range.length),
              let textRange = NSTextRange(location: start, end: end)
        else { return [] }
        layout.ensureLayout(for: textRange)
        var rects: [CGRect] = []
        layout.enumerateTextSegments(in: textRange, type: .standard, options: []) { _, frame, _, _ in
            if frame.width > 0, rects.contains(frame) == false {
                rects.append(frame)
            }
            return true
        }
        return rects
    }

    static func rects(of range: NSRange, in text: NSAttributedString, width: CGFloat) -> [CGRect] {
        let content = NSTextContentStorage()
        let layout = NSTextLayoutManager()
        content.addTextLayoutManager(layout)
        let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        layout.textContainer = container
        content.attributedString = text
        return rects(of: range, in: layout)
    }
}
