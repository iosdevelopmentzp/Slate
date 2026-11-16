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
    package var callout: String?
    package var isCalloutHeader: Bool
    package var isQuoted: Bool
    package var firstNumber: Int
    package var filePath: String?
    package var fileName: String?

    package init(kind: BlockKind = .body, indent: Int = 0, isDone: Bool = false, language: String? = nil, imagePath: String? = nil, imageAlt: String? = nil, group: Int = 0, table: TableBlock? = nil, callout: String? = nil, isCalloutHeader: Bool = false, isQuoted: Bool = false, firstNumber: Int = 1, filePath: String? = nil, fileName: String? = nil) {
        self.kind = kind
        self.indent = indent
        self.isDone = isDone
        self.language = language
        self.imagePath = imagePath
        self.imageAlt = imageAlt
        self.group = group
        self.table = table
        self.callout = callout
        self.isCalloutHeader = isCalloutHeader
        self.isQuoted = isQuoted
        self.firstNumber = firstNumber
        self.filePath = filePath
        self.fileName = fileName
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
        isQuoted = (kind.isList || kind == .image && indent > 0) && attributes[.slateQuoted] as? Bool == true
        callout = kind == .quote || isQuoted ? attributes[.slateCallout] as? String : nil
        isCalloutHeader = kind == .quote && callout != nil && attributes[.slateCalloutHeader] as? Bool == true
        firstNumber = kind == .numbered ? attributes[.slateFirstNumber] as? Int ?? 1 : 1
        filePath = kind == .file ? attributes[.slateFilePath] as? String : nil
        fileName = kind == .file ? attributes[.slateFileName] as? String : nil
    }

    package var attributes: [NSAttributedString.Key: Any] {
        var result: [NSAttributedString.Key: Any] = [.slateBlock: kind.rawValue]
        if kind.isList || kind == .image, indent > 0 { result[.slateIndent] = indent }
        if kind == .checklist, isDone { result[.slateDone] = true }
        if kind == .monospaced, let language { result[.slateLanguage] = language }
        if kind == .image, let imagePath { result[.slateImagePath] = imagePath }
        if kind == .image, let imageAlt, imageAlt.isEmpty == false { result[.slateImageAlt] = imageAlt }
        if kind == .file, let filePath { result[.slateFilePath] = filePath }
        if kind == .file, let fileName { result[.slateFileName] = fileName }
        if kind == .quote || kind.isList || isListImage, group != 0 { result[.slateGroup] = group }
        if kind == .table, let table { result[.slateTable] = table }
        if isQuoted, continuesList { result[.slateQuoted] = true }
        if kind == .numbered, firstNumber != 1 { result[.slateFirstNumber] = firstNumber }
        if isInQuote, let callout {
            result[.slateCallout] = callout
            if kind == .quote, isCalloutHeader { result[.slateCalloutHeader] = true }
        }
        return result
    }

    package var isListImage: Bool {
        kind == .image && indent > 0
    }

    package var continuesList: Bool {
        kind.isList || isListImage
    }

    package var isInQuote: Bool {
        kind == .quote || isQuoted && continuesList
    }

    package func with(kind: BlockKind) -> BlockAttributes {
        var copy = self
        copy.kind = kind
        if kind.isList == false { copy.indent = 0 }
        if kind != .checklist { copy.isDone = false }
        if kind != .table { copy.table = nil }
        if kind.isList == false { copy.isQuoted = false }
        if kind != .numbered { copy.firstNumber = 1 }
        if kind != .quote { copy.isCalloutHeader = false }
        if copy.isInQuote == false { copy.callout = nil }
        return copy
    }

    package static func of(_ text: NSAttributedString, paragraphAt location: Int) -> BlockAttributes {
        guard text.length > 0 else { return BlockAttributes() }
        let paragraph = (text.string as NSString).paragraphRange(for: NSRange(location: min(location, text.length - 1), length: 0))
        let index = min(paragraph.location, text.length - 1)
        return BlockAttributes(text.attributes(at: index, effectiveRange: nil))
    }
}
