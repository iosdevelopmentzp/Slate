import AppKit
import SlateDomain
import UniformTypeIdentifiers

enum PasteboardReader {
    static let dragTypes: [NSPasteboard.PasteboardType] = [.fileURL, .png, .tiff, NSPasteboard.PasteboardType(UTType.jpeg.identifier)]

    static func attachments(in pasteboard: NSPasteboard) -> [CaptureAttachment] {
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], urls.isEmpty == false {
            return urls.map(CaptureAttachment.file)
        }
        for (type, fileExtension) in [(NSPasteboard.PasteboardType.png, "png"), (.tiff, "tiff"), (NSPasteboard.PasteboardType(UTType.jpeg.identifier), "jpg")] {
            if let data = pasteboard.data(forType: type) {
                return [.image(data, fileExtension: fileExtension)]
            }
        }
        return []
    }
}
