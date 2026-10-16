import Foundation
import Markdown
import SlateDomain

struct HTMLExporter {
    func html(title: String, body: String) -> String {
        let content = HTMLFormatter.format(Document(parsing: body))
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
        body { font: 14px -apple-system, sans-serif; line-height: 1.5; max-width: 760px; margin: 32px auto; padding: 0 16px; }
        pre, code { font-family: ui-monospace, Menlo, monospace; font-size: 13px; }
        pre { background: #f4f4f4; padding: 8px 12px; border-radius: 6px; overflow-x: auto; }
        blockquote { border-left: 3px solid #ccc; margin-left: 0; padding-left: 12px; color: #555; }
        img { max-width: 100%; }
        </style>
        </head>
        <body>
        <h1>\(escaped)</h1>
        \(content)
        </body>
        </html>
        """
    }
}
