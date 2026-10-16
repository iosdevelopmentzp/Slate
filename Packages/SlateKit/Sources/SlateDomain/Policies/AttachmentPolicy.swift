import Foundation

package enum AttachmentPolicy {
    package static let folder = "_attachments"
    package static let maxImportSize = 50 * 1024 * 1024
    package static let sourceLength = 40

    private static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "heic", "heif", "tif", "tiff", "webp", "bmp"]

    package static func fileName(source: String, fileExtension: String, date: Date, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let stamp = String(format: "%04d%02d%02d-%02d%02d%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0, parts.hour ?? 0, parts.minute ?? 0, parts.second ?? 0)
        let ext = fileExtension.lowercased()
        return ext.isEmpty ? "\(stamp)-\(source)" : "\(stamp)-\(source).\(ext)"
    }

    package static func source(forOriginalName name: String) -> String {
        let stem = (name as NSString).deletingPathExtension
        let cleaned = StemPolicy.stem(forTitle: stem)
        let cut = String(cleaned.prefix(sourceLength)).trimmingCharacters(in: CharacterSet(charactersIn: " ."))
        return cut.isEmpty ? "file" : cut
    }

    package static func unique(_ name: String, among existing: [String]) -> String {
        let taken = Set(existing.map { $0.lowercased() })
        guard taken.contains(name.lowercased()) else { return name }
        let ns = name as NSString
        let stem = ns.deletingPathExtension
        let ext = ns.pathExtension
        var number = 2
        while true {
            let candidate = ext.isEmpty ? "\(stem)-\(number)" : "\(stem)-\(number).\(ext)"
            if taken.contains(candidate.lowercased()) == false { return candidate }
            number += 1
        }
    }

    package static func isImage(_ name: String) -> Bool {
        imageExtensions.contains((name as NSString).pathExtension.lowercased())
    }

    package static func relativeLink(to file: String, from note: VaultPath) -> String {
        let up = String(repeating: "../", count: max(note.depth, 0))
        return up + folder + "/" + encode(file)
    }

    package static func markdown(file: String, originalName: String? = nil, from note: VaultPath) -> String {
        let link = relativeLink(to: file, from: note)
        if isImage(file) {
            return "![](\(link))"
        }
        let label = (originalName ?? file).replacingOccurrences(of: "]", with: ")")
        return "[\(label)](\(link))"
    }

    package static func externalMarkdown(for url: URL) -> String {
        let label = url.lastPathComponent.replacingOccurrences(of: "]", with: ")")
        return isImage(url.lastPathComponent) ? "![](\(url.absoluteString))" : "[\(label)](\(url.absoluteString))"
    }

    package static func vaultPath(ofLink link: String, from note: VaultPath) -> String? {
        let target = link.split(separator: "#", maxSplits: 1).first.map(String.init) ?? link
        guard target.isEmpty == false, target.contains("://") == false, target.hasPrefix("/") == false else { return nil }
        let decoded = target.removingPercentEncoding ?? target
        var components = note.components.dropLast().map { $0 }
        for part in decoded.split(separator: "/", omittingEmptySubsequences: true) {
            switch part {
            case ".":
                continue
            case "..":
                guard components.isEmpty == false else { return nil }
                components.removeLast()
            default:
                components.append(String(part))
            }
        }
        guard components.isEmpty == false else { return nil }
        return components.joined(separator: "/")
    }

    package static func attachmentFile(ofLink link: String, from note: VaultPath) -> String? {
        guard let path = vaultPath(ofLink: link, from: note) else { return nil }
        let prefix = folder + "/"
        guard path.hasPrefix(prefix) else { return nil }
        let file = String(path.dropFirst(prefix.count))
        return file.isEmpty || file.contains("/") ? nil : file
    }

    private static func encode(_ file: String) -> String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "()<>[]")
        return file.addingPercentEncoding(withAllowedCharacters: allowed) ?? file
    }
}
