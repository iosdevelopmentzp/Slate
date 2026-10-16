import AppKit

nonisolated package struct EditorConfiguration: Equatable, Sendable {
    package static let baseTextSize: CGFloat = 15

    package var textSize: CGFloat
    package var colors: EditorColors
    package var imageMaxHeight: CGFloat

    package init(textSize: CGFloat = EditorConfiguration.baseTextSize, colors: EditorColors = .system, imageMaxHeight: CGFloat = 360) {
        self.textSize = textSize
        self.colors = colors
        self.imageMaxHeight = imageMaxHeight
    }

    package var scale: CGFloat {
        textSize / Self.baseTextSize
    }

    package static let standard = EditorConfiguration()
}
