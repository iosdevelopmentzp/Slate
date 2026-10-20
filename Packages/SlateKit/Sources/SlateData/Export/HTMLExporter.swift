import Foundation
import Markdown
import SlateDomain

struct HTMLExporter {
    private static let image = try! NSRegularExpression(pattern: #"<img src="([^"]+)""#)
    private static let imageTypes = ["png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg", "gif": "image/gif", "heic": "image/heic", "webp": "image/webp", "svg": "image/svg+xml", "tiff": "image/tiff", "tif": "image/tiff"]

    func html(title: String, body: String, folder: URL? = nil) -> String {
        let content = embeddingImages(in: HTMLFormatter.format(Document(parsing: body, options: [.disableSmartOpts])), folder: folder)
        let escaped = title
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        return """
        <!doctype html>
        <html>
        <head>
        <meta charset="utf-8">
        <title>\(escaped)</title>
        <style>
        body { font: 14px -apple-system, sans-serif; line-height: 1.5; max-width: 760px; margin: 32px auto; padding: 0 16px; color: #1d1d1f; }
        pre, code { font-family: ui-monospace, Menlo, monospace; font-size: 13px; }
        code { background: #f4f4f4; border-radius: 4px; padding: 1px 4px; }
        pre { background: #f4f4f4; padding: 8px 12px; margin: 14px 0; border-radius: 6px; overflow-x: auto; }
        pre code { background: none; padding: 0; }
        blockquote { border-left: 3px solid #ccc; margin-left: 0; padding-left: 12px; color: #555; }
        table { border-collapse: collapse; margin: 12px 0; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 6px 10px; text-align: left; vertical-align: top; }
        th { background: #f6f6f6; }
        mark { background: #FFF3A3A6; border-radius: 2px; }
        img { max-width: 100%; border-radius: 6px; }
        </style>
        </head>
        <body>
        <h1>\(escaped)</h1>
        \(content)
        </body>
        </html>
        """
    }

    private func embeddingImages(in html: String, folder: URL?) -> String {
        guard let folder else { return html }
        let ns = html as NSString
        var result = html
        for match in Self.image.matches(in: html, range: NSRange(location: 0, length: ns.length)).reversed() {
            let source = ns.substring(with: match.range(at: 1))
            guard source.contains("://") == false, source.hasPrefix("data:") == false else { continue }
            let decoded = source.removingPercentEncoding ?? source
            let url = decoded.hasPrefix("/") ? URL(fileURLWithPath: decoded) : folder.appendingPathComponent(decoded).standardizedFileURL
            guard let type = Self.imageTypes[url.pathExtension.lowercased()], let data = try? Data(contentsOf: url) else { continue }
            result = (result as NSString).replacingCharacters(in: match.range(at: 1), with: "data:\(type);base64,\(data.base64EncodedString())")
        }
        return result
    }
}
