import AppKit

enum TextSegmentRects {
    static func rects(of range: NSRange, in layout: NSTextLayoutManager) -> [CGRect] {
        var rects: [CGRect] = []
        for piece in pieces(of: range, in: layout) where rects.contains(piece.frame) == false {
            rects.append(piece.frame)
        }
        return rects
    }

    static func rects(of range: NSRange, in text: NSAttributedString, width: CGFloat) -> [CGRect] {
        rects(of: range, in: layout(of: text, width: width))
    }

    static func pieces(of range: NSRange, in text: NSAttributedString, width: CGFloat) -> [(range: NSRange, frame: CGRect, baseline: CGFloat)] {
        pieces(of: range, in: layout(of: text, width: width))
    }

    static func pieces(of range: NSRange, in layout: NSTextLayoutManager) -> [(range: NSRange, frame: CGRect, baseline: CGFloat)] {
        guard let content = layout.textContentManager,
              let start = content.location(content.documentRange.location, offsetBy: range.location),
              let end = content.location(start, offsetBy: range.length),
              let textRange = NSTextRange(location: start, end: end)
        else { return [] }
        layout.ensureLayout(for: textRange)
        var pieces: [(range: NSRange, frame: CGRect, baseline: CGFloat)] = []
        layout.enumerateTextSegments(in: textRange, type: .standard, options: []) { segment, frame, baseline, _ in
            guard frame.width > 0, let segment else { return true }
            let location = content.offset(from: content.documentRange.location, to: segment.location)
            let length = content.offset(from: segment.location, to: segment.endLocation)
            pieces.append((NSRange(location: location, length: length), frame, baseline))
            return true
        }
        return pieces
    }

    private static func layout(of text: NSAttributedString, width: CGFloat) -> NSTextLayoutManager {
        let content = NSTextContentStorage()
        let layout = NSTextLayoutManager()
        content.addTextLayoutManager(layout)
        let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        layout.textContainer = container
        content.attributedString = text
        return layout
    }
}
