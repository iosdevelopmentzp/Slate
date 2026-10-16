import Foundation

extension NSAttributedString.Key {
    static let slateBlock = NSAttributedString.Key("slate.block")
    static let slateIndent = NSAttributedString.Key("slate.indent")
    static let slateDone = NSAttributedString.Key("slate.done")
    static let slateLanguage = NSAttributedString.Key("slate.language")
    static let slateImagePath = NSAttributedString.Key("slate.imagePath")
    static let slateImageAlt = NSAttributedString.Key("slate.imageAlt")
    static let slateGroup = NSAttributedString.Key("slate.group")
    static let slateInline = NSAttributedString.Key("slate.inline")
    static let slateHref = NSAttributedString.Key("slate.href")
    static let slateHardBreak = NSAttributedString.Key("slate.hardBreak")
    static let slateListNumber = NSAttributedString.Key("slate.listNumber")

    static let blockKeys: [NSAttributedString.Key] = [.slateBlock, .slateIndent, .slateDone, .slateLanguage, .slateImagePath, .slateImageAlt, .slateGroup]
}
