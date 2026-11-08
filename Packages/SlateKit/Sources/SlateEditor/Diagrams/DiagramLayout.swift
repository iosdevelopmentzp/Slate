import AppKit

nonisolated enum DiagramLayout {
    static let padding: CGFloat = 12
    static let topPadding: CGFloat = 28
    static let pendingHeight: CGFloat = 40
    static let errorLineHeight: CGFloat = 15
    static let errorGap: CGFloat = 6
    static let maxErrorLines = 4
    static let hiddenLineHeight: CGFloat = 0.01

    static var errorFont: NSFont { .monospacedSystemFont(ofSize: 11, weight: .regular) }

    static func displaySize(of size: CGSize, blockWidth: CGFloat, scale: CGFloat) -> CGSize {
        let natural = CGSize(width: size.width * scale, height: size.height * scale)
        let available = blockWidth - padding * 2
        guard available > 0, natural.width > available, natural.width > 0 else {
            return CGSize(width: natural.width.rounded(), height: natural.height.rounded())
        }
        let factor = available / natural.width
        return CGSize(width: available.rounded(), height: (natural.height * factor).rounded())
    }

    static func errorLines(_ message: String) -> [String] {
        let lines = message.components(separatedBy: .newlines).filter { $0.trimmingCharacters(in: .whitespaces).isEmpty == false }
        return Array(lines.prefix(maxErrorLines))
    }

    static func areaHeight(of picture: DiagramPicture?, blockWidth: CGFloat, scale: CGFloat) -> CGFloat {
        guard let picture, picture.image != nil || picture.error != nil else { return pendingHeight }
        var height = topPadding + padding
        if picture.image != nil {
            height += displaySize(of: picture.size, blockWidth: blockWidth, scale: scale).height
        }
        if let error = picture.error {
            height += CGFloat(errorLines(error).count) * errorLineHeight + (picture.image == nil ? 0 : errorGap)
        }
        return height.rounded()
    }
}
