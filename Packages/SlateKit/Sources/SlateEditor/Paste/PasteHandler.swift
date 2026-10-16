import AppKit

enum PasteHandler {
    static func snapshot(of pasteboard: NSPasteboard) -> PasteboardSnapshot {
        var snapshot = PasteboardSnapshot()
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] {
            snapshot.fileURLs = urls.filter(\.isFileURL)
        }
        if let png = pasteboard.data(forType: .png) {
            snapshot.image = (png, "png")
        } else if let tiff = pasteboard.data(forType: .tiff), let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) {
            snapshot.image = (png, "png")
        }
        snapshot.string = pasteboard.string(forType: .string)
        snapshot.html = pasteboard.string(forType: .html)
        return snapshot
    }

    static func copy(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }

    static var clipboardURL: String? {
        NSPasteboard.general.string(forType: .string).flatMap(PasteClassifier.singleURL)
    }
}
