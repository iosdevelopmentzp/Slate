import AppKit
import UniformTypeIdentifiers

nonisolated final class FileAttachment: NSTextAttachment {
    static let height: CGFloat = 52
    static let maxWidth: CGFloat = 360
    static let cornerRadius: CGFloat = 10
    static let iconSize: CGFloat = 36

    let path: String
    let name: String
    let url: URL?
    let colors: EditorColors
    private let icon: NSImage
    private let detail: String

    init(path: String, name: String, url: URL?, colors: EditorColors) {
        self.path = path
        self.name = name
        self.url = url
        self.colors = colors
        let exists = url.map { FileManager.default.fileExists(atPath: $0.path) } ?? false
        icon = Self.icon(for: url, name: name, exists: exists)
        detail = exists ? Self.detail(for: url, name: name) : "File not found"
        super.init(data: nil, ofType: nil)
        allowsTextAttachmentView = false
        image = rendered(size: CGSize(width: Self.maxWidth, height: Self.height))
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func attachmentBounds(for attributes: [NSAttributedString.Key: Any], location: any NSTextLocation, textContainer: NSTextContainer?, proposedLineFragment: CGRect, position: CGPoint) -> CGRect {
        let padding = textContainer?.lineFragmentPadding ?? 5
        let available = (textContainer?.size.width ?? proposedLineFragment.width) - padding * 2
        return CGRect(x: 0, y: 0, width: max(min(available, Self.maxWidth), 160).rounded(), height: Self.height)
    }

    override func image(for bounds: CGRect, attributes: [NSAttributedString.Key: Any], location: any NSTextLocation, textContainer: NSTextContainer?) -> NSImage? {
        rendered(size: bounds.size)
    }

    private static func icon(for url: URL?, name: String, exists: Bool) -> NSImage {
        if exists, let url {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        let type = UTType(filenameExtension: (name as NSString).pathExtension) ?? .data
        return NSWorkspace.shared.icon(for: type)
    }

    private static func detail(for url: URL?, name: String) -> String {
        let type = UTType(filenameExtension: (name as NSString).pathExtension)
        let kind = type?.localizedDescription ?? "File"
        guard let url, let size = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int64 else { return kind }
        return kind + " · " + ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    private func rendered(size: CGSize) -> NSImage {
        let icon = icon
        let colors = colors
        let title = NSAttributedString(string: name, attributes: [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: colors.text,
            .paragraphStyle: Self.truncating,
        ])
        let subtitle = NSAttributedString(string: detail, attributes: [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: colors.secondaryText,
            .paragraphStyle: Self.truncating,
        ])
        return NSImage(size: size, flipped: true) { rect in
            let shape = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: Self.cornerRadius, yRadius: Self.cornerRadius)
            colors.codeBackground.setFill()
            shape.fill()
            colors.imageBorder.setStroke()
            shape.lineWidth = 1
            shape.stroke()
            let iconRect = CGRect(x: rect.minX + 10, y: rect.midY - Self.iconSize / 2, width: Self.iconSize, height: Self.iconSize)
            icon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
            let textX = iconRect.maxX + 10
            let textWidth = max(rect.maxX - 12 - textX, 0)
            title.draw(in: CGRect(x: textX, y: rect.midY - 18, width: textWidth, height: 18))
            subtitle.draw(in: CGRect(x: textX, y: rect.midY + 1, width: textWidth, height: 16))
            return true
        }
    }

    private static var truncating: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingMiddle
        return style
    }
}
