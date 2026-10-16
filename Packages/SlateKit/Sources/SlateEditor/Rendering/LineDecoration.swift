import AppKit

nonisolated enum LineDecoration {
    case codeBlock(isFirst: Bool, isLast: Bool)
    case quote
    case checkbox(isChecked: Bool, location: Int)
    case rule
    case image(NSImage, size: CGSize, source: String)
}
