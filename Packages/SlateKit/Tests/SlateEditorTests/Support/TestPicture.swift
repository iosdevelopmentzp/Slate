import AppKit

final class TestPicture {
    let folder: URL
    let url: URL

    init(name: String = "a.png", size: CGSize = CGSize(width: 40, height: 20)) throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent("slate-picture-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        url = folder.appendingPathComponent(name)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.systemBlue.setFill()
            rect.fill()
            return true
        }
        guard let bitmap = image.tiffRepresentation.flatMap(NSBitmapImageRep.init(data:)),
              let data = bitmap.representation(using: .png, properties: [:]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url)
    }

    deinit {
        try? FileManager.default.removeItem(at: folder)
    }
}
