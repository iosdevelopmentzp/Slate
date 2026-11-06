import AppKit

final class TailMarkerView: NSView {
    static let numberRoom: CGFloat = 40

    private(set) var decoration: ParagraphDecoration = .none
    private var fontSize: CGFloat = 15
    private var colors: EditorColors = .system

    override var isFlipped: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        ListMarker.draw(decoration, in: markerRect, fontSize: fontSize, colors: colors, context: context)
    }

    var markerRect: CGRect {
        CGRect(x: Self.numberRoom + 2, y: 2, width: bounds.width - Self.numberRoom - 4, height: bounds.height - 4)
    }

    func show(_ decoration: ParagraphDecoration, at rect: CGRect, fontSize: CGFloat, colors: EditorColors) {
        let frame = CGRect(x: rect.minX - Self.numberRoom - 2, y: rect.minY - 2, width: rect.width + Self.numberRoom + 4, height: rect.height + 4)
        isHidden = false
        guard decoration != self.decoration || frame != self.frame || fontSize != self.fontSize || colors != self.colors else { return }
        self.decoration = decoration
        self.fontSize = fontSize
        self.colors = colors
        self.frame = frame
        needsDisplay = true
    }

    func hide() {
        isHidden = true
        decoration = .none
    }
}
