import Foundation

nonisolated package struct BlockAttributes: Hashable, Sendable {
    package var kind: BlockKind
    package var indent: Int
    package var isDone: Bool
    package var language: String?
    package var imagePath: String?
    package var imageAlt: String?
    package var group: Int
    package var table: TableBlock?

    package init(kind: BlockKind = .body, indent: Int = 0, isDone: Bool = false, language: String? = nil, imagePath: String? = nil, imageAlt: String? = nil, group: Int = 0, table: TableBlock? = nil) {
        self.kind = kind
        self.indent = indent
        self.isDone = isDone
        self.language = language
        self.imagePath = imagePath
        self.imageAlt = imageAlt
        self.group = group
        self.table = table
    }

    package init(_ attributes: [NSAttributedString.Key: Any]) {
        let kind = (attributes[.slateBlock] as? String).flatMap(BlockKind.init(rawValue:)) ?? .body
        self.kind = kind
        indent = min(max(attributes[.slateIndent] as? Int ?? 0, 0), kind == .image ? RichText.maxIndent + 1 : RichText.maxIndent)
        isDone = attributes[.slateDone] as? Bool ?? false
        language = attributes[.slateLanguage] as? String
        imagePath = attributes[.slateImagePath] as? String
        imageAlt = attributes[.slateImageAlt] as? String
        group = attributes[.slateGroup] as? Int ?? 0
        table = attributes[.slateTable] as? TableBlock
    }

    package var attributes: [NSAttributedString.Key: Any] {
        var result: [NSAttributedString.Key: Any] = [.slateBlock: kind.rawValue]
        if kind.isList || kind == .image, indent > 0 { result[.slateIndent] = indent }
        if kind == .checklist, isDone { result[.slateDone] = true }
        if kind == .monospaced, let language { result[.slateLanguage] = language }
        if kind == .image, let imagePath { result[.slateImagePath] = imagePath }
        if kind == .image, let imageAlt, imageAlt.isEmpty == false { result[.slateImageAlt] = imageAlt }
        if kind == .quote || kind.isList || isListImage, group != 0 { result[.slateGroup] = group }
        if kind == .table, let table { result[.slateTable] = table }
        return result
    }

    package var isListImage: Bool {
        kind == .image && indent > 0
    }

    package var continuesList: Bool {
        kind.isList || isListImage
    }

    package func with(kind: BlockKind) -> BlockAttributes {
        var copy = self
        copy.kind = kind
        if kind.isList == false { copy.indent = 0 }
        if kind != .checklist { copy.isDone = false }
        if kind != .table { copy.table = nil }
        return copy
    }

    package static func of(_ text: NSAttributedString, paragraphAt location: Int) -> BlockAttributes {
        guard text.length > 0 else { return BlockAttributes() }
        let paragraph = (text.string as NSString).paragraphRange(for: NSRange(location: min(location, text.length - 1), length: 0))
        let index = min(paragraph.location, text.length - 1)
        return BlockAttributes(text.attributes(at: index, effectiveRange: nil))
    }
}
