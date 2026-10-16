import Foundation

extension NSAttributedString.Key {
    nonisolated static let slateBlock = NSAttributedString.Key("slate.block")
    nonisolated static let slateIndent = NSAttributedString.Key("slate.indent")
    nonisolated static let slateDone = NSAttributedString.Key("slate.done")
    nonisolated static let slateLanguage = NSAttributedString.Key("slate.language")
    nonisolated static let slateImagePath = NSAttributedString.Key("slate.imagePath")
    nonisolated static let slateImageAlt = NSAttributedString.Key("slate.imageAlt")
    nonisolated static let slateGroup = NSAttributedString.Key("slate.group")
    nonisolated static let slateInline = NSAttributedString.Key("slate.inline")
    nonisolated static let slateHref = NSAttributedString.Key("slate.href")
    nonisolated static let slateHardBreak = NSAttributedString.Key("slate.hardBreak")
    nonisolated static let slateListNumber = NSAttributedString.Key("slate.listNumber")

    nonisolated static let blockKeys: [NSAttributedString.Key] = [.slateBlock, .slateIndent, .slateDone, .slateLanguage, .slateImagePath, .slateImageAlt, .slateGroup]
}
