import AppKit

final class CaretOverlay: NSView {
    static let width: CGFloat = 2
    static let blinkInterval: Duration = .milliseconds(530)

    var color = NSColor.textColor
    private(set) var rects: [NSRect] = []
    private var isLit = true
    private var blink: Task<Void, Never>?

    override var isFlipped: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func draw(_ dirtyRect: NSRect) {
        guard isLit else { return }
        color.setFill()
        for rect in rects {
            NSRect(x: rect.minX, y: rect.minY, width: Self.width, height: rect.height).fill()
        }
    }

    func show(_ rects: [NSRect]) {
        self.rects = rects
        isHidden = rects.isEmpty
        isLit = true
        needsDisplay = true
        blink?.cancel()
        blink = nil
        guard rects.isEmpty == false else { return }
        blink = Task { @MainActor [weak self] in
            guard let self else { return }
            await blinkUntilCancelled()
        }
    }

    private func blinkUntilCancelled() async {
        while Task.isCancelled == false {
            try? await Task.sleep(for: Self.blinkInterval)
            guard Task.isCancelled == false else { return }
            isLit.toggle()
            needsDisplay = true
        }
    }
}
