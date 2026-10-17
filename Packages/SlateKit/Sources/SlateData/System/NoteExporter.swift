import AppKit
import SlateDomain

struct NoteExporter: NoteExporting {
    let formatter = HTMLExporter()
    var downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())

    func html(title: String, body: String) -> String {
        formatter.html(title: title, body: body)
    }

    func pdf(title: String, body: String) async throws -> Data {
        let page = html(title: title, body: body)
        return try await MainActor.run {
            guard let data = page.data(using: .utf8),
                  let attributed = NSAttributedString(html: data, options: [.characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil) else {
                throw CocoaError(.fileWriteUnknown)
            }
            let width: CGFloat = 612
            let view = NSTextView(frame: NSRect(x: 0, y: 0, width: width, height: 792))
            view.textContainerInset = NSSize(width: 48, height: 48)
            view.textStorage?.setAttributedString(attributed)
            view.sizeToFit()
            let height = max(view.frame.height, 792)
            view.frame = NSRect(x: 0, y: 0, width: width, height: height)
            return view.dataWithPDF(inside: view.bounds)
        }
    }

    func saveToDownloads(_ data: Data, fileName: String) async throws -> URL {
        let url = freeURL(for: fileName)
        try data.write(to: url, options: .atomic)
        return url
    }

    func copyToDownloads(_ source: URL) async throws -> URL {
        let url = freeURL(for: source.lastPathComponent)
        try FileManager.default.copyItem(at: source, to: url)
        return url
    }

    private func freeURL(for fileName: String) -> URL {
        let cleaned = fileName.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
        let base = (cleaned as NSString).deletingPathExtension
        let ext = (cleaned as NSString).pathExtension
        var url = downloads.appendingPathComponent(cleaned)
        var number = 2
        while FileManager.default.fileExists(atPath: url.path) {
            url = downloads.appendingPathComponent(ext.isEmpty ? "\(base) \(number)" : "\(base) \(number).\(ext)")
            number += 1
        }
        return url
    }
}
