import Foundation

struct LinkPreview: Equatable {
    let symbol: String
    let title: String
    let detail: String

    init(href: String) {
        if LinkAddress.isNote(href) {
            self.init(symbol: "doc.text", title: LinkAddress.display(href), detail: "Note in Slate")
        } else if href.lowercased().hasPrefix("mailto:") {
            self.init(symbol: "envelope", title: String(href.dropFirst("mailto:".count)), detail: "Email")
        } else if let path = Self.filePath(href) {
            let url = URL(fileURLWithPath: path)
            let folder = (url.deletingLastPathComponent().path as NSString).abbreviatingWithTildeInPath
            self.init(symbol: "doc", title: url.lastPathComponent, detail: folder)
        } else if let url = URL(string: href), let host = url.host(), host.isEmpty == false, ["http", "https"].contains(url.scheme?.lowercased()) {
            self.init(symbol: "globe", title: Self.site(host), detail: Self.page(url) ?? "Web page")
        } else {
            self.init(symbol: "link", title: href, detail: "Opens in another app")
        }
    }

    private init(symbol: String, title: String, detail: String) {
        self.symbol = symbol
        self.title = title
        self.detail = detail
    }

    private static func filePath(_ href: String) -> String? {
        if href.hasPrefix("file://") {
            return URL(string: href)?.path
        }
        guard ["/", "~/"].contains(where: href.hasPrefix) else { return nil }
        return (href as NSString).expandingTildeInPath
    }

    private static func site(_ host: String) -> String {
        host.lowercased().hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    private static func page(_ url: URL) -> String? {
        var page = url.path(percentEncoded: false).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if let query = url.query(percentEncoded: false), query.isEmpty == false {
            page += (page.isEmpty ? "" : " ") + "?" + query
        }
        if let fragment = url.fragment(percentEncoded: false), fragment.isEmpty == false {
            page += (page.isEmpty ? "" : " ") + "#" + fragment
        }
        return page.isEmpty ? nil : page
    }
}
