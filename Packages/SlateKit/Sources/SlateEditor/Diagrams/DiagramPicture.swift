import AppKit

nonisolated final class DiagramPicture: NSObject {
    let image: NSImage?
    let size: CGSize
    let error: String?

    init(image: NSImage?, size: CGSize, error: String? = nil) {
        self.image = image
        self.size = size
        self.error = error
    }

    func failed(_ message: String) -> DiagramPicture {
        DiagramPicture(image: image, size: size, error: message)
    }
}
