import AppKit

package enum EditorMenuActions {
    package static let bold = #selector(MarkdownTextView.slateBold(_:))
    package static let italic = #selector(MarkdownTextView.slateItalic(_:))
    package static let code = #selector(MarkdownTextView.slateCode(_:))
    package static let link = #selector(MarkdownTextView.slateLink(_:))
    package static let toggleCheckbox = #selector(MarkdownTextView.slateToggleCheckbox(_:))
    package static let moveLineUp = #selector(MarkdownTextView.slateMoveLineUp(_:))
    package static let moveLineDown = #selector(MarkdownTextView.slateMoveLineDown(_:))
    package static let duplicateLine = #selector(MarkdownTextView.slateDuplicateLine(_:))
    package static let toggleComment = #selector(MarkdownTextView.slateToggleComment(_:))
    package static let pasteAsCode = #selector(MarkdownTextView.slatePasteAsCode(_:))
    package static let find = #selector(MarkdownTextView.slateFind(_:))
    package static let findAndReplace = #selector(MarkdownTextView.slateFindAndReplace(_:))
    package static let screenshot = #selector(MarkdownTextView.slateScreenshot(_:))
    package static let windowScreenshot = #selector(MarkdownTextView.slateWindowScreenshot(_:))
    package static let openLink = #selector(MarkdownTextView.slateOpenLink(_:))
}
