import AppKit

nonisolated final class RichLayoutFragment: NSTextLayoutFragment {
    enum Fold {
        case open
        case closed
    }

    var decoration: ParagraphDecoration = .none
    var fold: Fold?
    var colors: EditorColors = .system
    var fontSize: CGFloat = 15
    var languageLabel: String?
    var calloutPlaceholder: String?
    var isDiagram = false
    var diagram: DiagramPicture?
    var diagramArea: CGFloat = 0
    var diagramScale: CGFloat = 1
    var hidesCode = false

    static var labelFont: NSFont { .systemFont(ofSize: 10, weight: .medium) }

    override var renderingSurfaceBounds: CGRect {
        var bounds = super.renderingSurfaceBounds
        switch decoration {
        case .block:
            bounds = bounds.union(blockRect.insetBy(dx: -1, dy: -1))
        case .quote:
            bounds = bounds.union(quoteRect)
        case .callout:
            bounds = bounds.union(calloutRect)
        case .bullet, .number, .checkbox:
            bounds = bounds.union(markerRect.insetBy(dx: -2, dy: -2))
        case .none:
            break
        }
        if fold != nil {
            bounds = bounds.union(foldRect.insetBy(dx: -2, dy: -2))
        }
        return bounds
    }

    override func draw(at point: CGPoint, in context: CGContext) {
        context.saveGState()
        context.translateBy(x: point.x, y: point.y)
        drawBackground(in: context)
        context.restoreGState()
        super.draw(at: point, in: context)
        context.saveGState()
        context.translateBy(x: point.x, y: point.y)
        drawMarker(in: context)
        drawDiagram(in: context)
        drawCalloutHeader(in: context)
        drawLanguageLabel(in: context)
        drawFold(in: context)
        context.restoreGState()
    }

    var languageLabelRect: CGRect {
        guard let languageLabel, decoration == .block(raw: false) else { return .zero }
        let size = NSAttributedString(string: languageLabel, attributes: [.font: Self.labelFont]).size()
        let block = blockRect
        return CGRect(x: block.maxX - size.width - 14, y: block.minY + 4, width: size.width + 8, height: size.height + 2)
    }

    private func drawLanguageLabel(in context: CGContext) {
        let rect = languageLabelRect
        guard let languageLabel, rect.isEmpty == false else { return }
        context.addPath(CGPath(roundedRect: rect, cornerWidth: 4, cornerHeight: 4, transform: nil))
        context.setFillColor(colors.codeBackground.cgColor)
        context.fillPath()
        let text = NSAttributedString(string: languageLabel, attributes: [.font: Self.labelFont, .foregroundColor: colors.secondaryText])
        draw(text, at: CGPoint(x: rect.minX + 4, y: rect.minY + 1), in: context)
    }

    var foldRect: CGRect {
        guard fold != nil, let line = textLineFragments.first else { return .zero }
        let start = line.typographicBounds.minX + line.locationForCharacter(at: 0).x
        let side: CGFloat = 12
        let center = line.typographicBounds.minY + line.glyphOrigin.y - fontSize * 0.36
        return CGRect(x: start - side - 4, y: center - side / 2, width: side, height: side)
    }

    private func drawFold(in context: CGContext) {
        let rect = foldRect.insetBy(dx: 3, dy: 3)
        guard let fold, rect.isEmpty == false else { return }
        context.setStrokeColor(colors.secondaryText.cgColor)
        context.setLineWidth(1.6)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        switch fold {
        case .closed:
            context.move(to: CGPoint(x: rect.minX + 1.5, y: rect.minY))
            context.addLine(to: CGPoint(x: rect.maxX - 1.5, y: rect.midY))
            context.addLine(to: CGPoint(x: rect.minX + 1.5, y: rect.maxY))
        case .open:
            context.move(to: CGPoint(x: rect.minX, y: rect.minY + 1.5))
            context.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 1.5))
            context.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 1.5))
        }
        context.strokePath()
    }

    var markerRect: CGRect {
        guard let line = textLineFragments.first else { return .zero }
        let start = line.typographicBounds.minX + line.locationForCharacter(at: 0).x
        return ListMarker.rect(lineStart: start, baseline: line.typographicBounds.minY + line.glyphOrigin.y, fontSize: fontSize)
    }

    private var textBounds: CGRect {
        guard let first = textLineFragments.first, let last = textLineFragments.last else { return .zero }
        return CGRect(x: 0, y: first.typographicBounds.minY, width: containerWidth, height: last.typographicBounds.maxY - first.typographicBounds.minY)
    }

    private var containerWidth: CGFloat {
        textLayoutManager?.textContainer?.size.width ?? layoutFragmentFrame.width
    }

    private var padding: CGFloat {
        textLayoutManager?.textContainer?.lineFragmentPadding ?? 5
    }

    var blockRect: CGRect {
        let text = textBounds
        let top = text.minY - 6 - diagramArea
        let bottom = text.maxY + (hidesCode ? 0 : 6)
        return CGRect(x: padding - layoutFragmentFrame.minX, y: top, width: containerWidth - padding * 2, height: bottom - top)
    }

    var diagramRect: CGRect {
        guard isDiagram else { return .zero }
        let block = blockRect
        return CGRect(x: block.minX, y: block.minY, width: block.width, height: diagramArea)
    }

    private func drawDiagram(in context: CGContext) {
        let area = diagramRect
        guard area.isEmpty == false else { return }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
        defer { NSGraphicsContext.restoreGraphicsState() }
        guard let diagram, diagram.image != nil || diagram.error != nil else {
            let text = NSAttributedString(string: "Drawing diagram…", attributes: [.font: Self.labelFont, .foregroundColor: colors.secondaryText])
            let size = text.size()
            text.draw(at: CGPoint(x: area.midX - size.width / 2, y: area.midY - size.height / 2))
            return
        }
        var top = area.minY + DiagramLayout.topPadding
        if let image = diagram.image {
            let size = DiagramLayout.displaySize(of: diagram.size, blockWidth: area.width, scale: diagramScale)
            let rect = CGRect(x: (area.midX - size.width / 2).rounded(), y: top, width: size.width, height: size.height)
            image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
            top = rect.maxY + DiagramLayout.errorGap
        }
        guard let error = diagram.error else { return }
        for line in DiagramLayout.errorLines(error) {
            let text = NSAttributedString(string: line, attributes: [.font: DiagramLayout.errorFont, .foregroundColor: NSColor.systemRed])
            text.draw(with: CGRect(x: area.minX + DiagramLayout.padding, y: top, width: area.width - DiagramLayout.padding * 2, height: DiagramLayout.errorLineHeight), options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])
            top += DiagramLayout.errorLineHeight
        }
    }

    private var quoteRect: CGRect {
        let text = textBounds
        return CGRect(x: padding + 2 - layoutFragmentFrame.minX, y: text.minY + 2, width: 3, height: max(text.height - 4, 4))
    }

    private func drawBackground(in context: CGContext) {
        switch decoration {
        case .block(let raw):
            context.addPath(CGPath(roundedRect: blockRect, cornerWidth: 8, cornerHeight: 8, transform: nil))
            context.setFillColor((raw ? colors.rawBackground : colors.codeBackground).cgColor)
            context.fillPath()
        case .quote:
            context.addPath(CGPath(roundedRect: quoteRect, cornerWidth: 1.5, cornerHeight: 1.5, transform: nil))
            context.setFillColor(colors.quoteBar.cgColor)
            context.fillPath()
        case .callout(let marker, _):
            let color = CalloutKind(marker: marker).color
            let rect = calloutRect
            context.setFillColor(color.withAlphaComponent(0.09).cgColor)
            context.fill(rect)
            context.setFillColor(color.cgColor)
            context.fill(CGRect(x: rect.minX, y: rect.minY, width: 3, height: rect.height))
        default:
            break
        }
    }

    private var calloutRect: CGRect {
        CGRect(x: padding - layoutFragmentFrame.minX, y: 0, width: containerWidth - padding * 2, height: layoutFragmentFrame.height)
    }

    private func drawCalloutHeader(in context: CGContext) {
        guard case .callout(let marker, true) = decoration, let line = textLineFragments.first else { return }
        let kind = CalloutKind(marker: marker)
        let baseline = line.typographicBounds.minY + line.glyphOrigin.y
        let left = padding - layoutFragmentFrame.minX + RichTextStyler.quoteIndent
        let configuration = NSImage.SymbolConfiguration(pointSize: fontSize * 0.9, weight: .semibold).applying(.init(paletteColors: [kind.color]))
        if let image = NSImage(systemSymbolName: kind.symbol, accessibilityDescription: kind.title)?.withSymbolConfiguration(configuration) {
            let size = image.size
            let rect = CGRect(x: left, y: baseline - fontSize * 0.36 - size.height / 2, width: size.width, height: size.height)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
            image.draw(in: rect)
            NSGraphicsContext.restoreGraphicsState()
        }
        guard let calloutPlaceholder else { return }
        let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        let text = NSAttributedString(string: calloutPlaceholder, attributes: [.font: font, .foregroundColor: kind.color])
        draw(text, at: CGPoint(x: left + RichTextStyler.calloutIconWidth, y: baseline - font.ascender), in: context)
    }

    private func drawMarker(in context: CGContext) {
        let rect = markerRect
        guard rect.isEmpty == false else { return }
        ListMarker.draw(decoration, in: rect, fontSize: fontSize, colors: colors, context: context)
    }

    private func draw(_ text: NSAttributedString, at point: CGPoint, in context: CGContext) {
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
        text.draw(at: point)
        NSGraphicsContext.restoreGraphicsState()
    }
}
