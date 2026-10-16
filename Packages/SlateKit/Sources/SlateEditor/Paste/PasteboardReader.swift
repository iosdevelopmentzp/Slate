import AppKit
import UniformTypeIdentifiers

enum PasteboardReader {
    static let markdownType = NSPasteboard.PasteboardType("app.slate.markdown")

    enum Content {
        case markdown(String)
        case files([URL])
        case image(Data, String)
        case html(Data)
        case text(String)
    }

    static func urlString() -> String? {
        let text = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return text?.looksLikeURL == true ? text : nil
    }

    static func read(_ pasteboard: NSPasteboard) -> Content? {
        if let markdown = pasteboard.string(forType: markdownType) {
            return .markdown(markdown)
        }
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], urls.isEmpty == false {
            return .files(urls)
        }
        for (type, fileExtension) in [(NSPasteboard.PasteboardType.png, "png"), (.tiff, "tiff"), (NSPasteboard.PasteboardType(UTType.jpeg.identifier), "jpg")] {
            if let data = pasteboard.data(forType: type) {
                return .image(data, fileExtension)
            }
        }
        if let html = pasteboard.data(forType: .html) {
            return .html(html)
        }
        if let text = pasteboard.string(forType: .string) {
            return .text(text)
        }
        return nil
    }

    static func write(markdown: String, plain: String, to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        pasteboard.declareTypes([markdownType, .string], owner: nil)
        pasteboard.setString(markdown, forType: markdownType)
        pasteboard.setString(plain, forType: .string)
    }
}
