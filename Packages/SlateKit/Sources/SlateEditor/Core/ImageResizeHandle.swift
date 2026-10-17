import AppKit

final class ImageResizeHandle: NSView {
    static let side: CGFloat = 16
    static let inset: CGFloat = 6

    private(set) var location: Int?
    private(set) var isDragging = false
    private var startX: CGFloat = 0
    private var startWidth: CGFloat = 0
    var onResize: (Int, CGFloat) -> Void = { _, _ in }
    var onFinish: (Int, CGFloat) -> Void = { _, _ in }

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: Self.side, height: Self.side))
        toolTip = "Drag to resize"
        isHidden = true
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .resizeLeftRight)
    }

    override func draw(_ dirtyRect: NSRect) {
        let shape = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 4, yRadius: 4)
        NSColor.black.withAlphaComponent(0.55).setFill()
        shape.fill()
        NSColor.white.setStroke()
        let grip = NSBezierPath()
        grip.lineWidth = 1.2
        for offset in [4.0, 8.0] {
            grip.move(to: CGPoint(x: bounds.maxX - 4, y: bounds.maxY - 4 - offset))
            grip.line(to: CGPoint(x: bounds.maxX - 4 - offset, y: bounds.maxY - 4))
        }
        grip.stroke()
    }

    override var isFlipped: Bool {
        true
    }

    func show(location: Int, over image: CGRect, in view: NSView) {
        guard isDragging == false else { return }
        guard image.width >= ImageSaveButton.smallestImage, image.height >= ImageSaveButton.smallestImage else {
            hide()
            return
        }
        self.location = location
        if superview !== view {
            view.addSubview(self)
        }
        place(over: image, in: view)
        isHidden = false
    }

    func place(over image: CGRect, in view: NSView) {
        let y = view.isFlipped ? image.maxY - Self.inset - Self.side : image.minY + Self.inset
        frame = NSRect(x: image.maxX - Self.inset - Self.side, y: y, width: Self.side, height: Self.side)
        startWidth = isDragging ? startWidth : image.width
    }

    func hide() {
        guard isDragging == false else { return }
        location = nil
        isHidden = true
    }

    override func mouseDown(with event: NSEvent) {
        guard location != nil else { return }
        isDragging = true
        startX = event.locationInWindow.x
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDragging, let location else { return }
        onResize(location, width(for: event))
    }

    override func mouseUp(with event: NSEvent) {
        guard isDragging, let location else { return }
        let width = width(for: event)
        isDragging = false
        onFinish(location, width)
    }

    private func width(for event: NSEvent) -> CGFloat {
        max(startWidth + event.locationInWindow.x - startX, ImageAttachment.smallestWidth).rounded()
    }
}
