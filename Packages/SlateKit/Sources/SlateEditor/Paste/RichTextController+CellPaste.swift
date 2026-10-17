import AppKit

extension RichTextController {
    static let cellDropTypes: [NSPasteboard.PasteboardType] = [.fileURL, .png, .tiff]

    func pasteIntoCell(_ view: TableBlockView) {
        pasteIntoCell(view, from: PasteboardBridge.general)
    }

    func pasteIntoCell(_ view: TableBlockView, from pasteboard: NSPasteboard) {
        guard let content = PasteboardReader.read(pasteboard) else { return }
        switch content {
        case .files(let urls):
            imageTarget = view.imageTarget
            handlers.pasteFiles(urls)
        case .image(let data, let fileExtension):
            imageTarget = view.imageTarget
            handlers.pasteImage(data, fileExtension)
        case .markdown(let markdown):
            view.insertInline(markdown.components(separatedBy: .newlines).filter { $0.isEmpty == false }.joined(separator: " "))
        case .html, .text:
            view.cellEditor.pasteAsPlainText(nil)
        }
    }

    func dropIntoCell(_ dragging: any NSDraggingInfo, target: TableImageTarget) -> Bool {
        guard let content = PasteboardReader.read(dragging.draggingPasteboard) else { return false }
        switch content {
        case .files(let urls):
            imageTarget = target
            handlers.pasteFiles(urls)
            return true
        case .image(let data, let fileExtension):
            imageTarget = target
            handlers.pasteImage(data, fileExtension)
            return true
        default:
            return false
        }
    }
}
