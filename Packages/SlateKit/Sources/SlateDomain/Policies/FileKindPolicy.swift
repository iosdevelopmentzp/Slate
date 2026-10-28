import Foundation

package enum FileKindPolicy {
    package static let textLimit = 4 * 1024 * 1024

    private static let previewExtensions: Set<String> = [
        "pdf", "rtf", "rtfd", "html", "htm", "svg", "webarchive",
        "doc", "docx", "xls", "xlsx", "ppt", "pptx", "pages", "numbers", "key", "odt", "ods", "odp", "epub",
        "png", "jpg", "jpeg", "gif", "heic", "heif", "tif", "tiff", "webp", "bmp", "ico", "icns", "psd",
        "mov", "mp4", "m4v", "avi", "mkv", "mp3", "m4a", "wav", "aiff", "aif", "flac", "caf",
        "zip", "gz", "tgz", "bz2", "xz", "7z", "rar", "dmg", "pkg", "ipa", "app", "xcarchive",
        "sqlite", "db", "realm", "a", "o", "dylib", "so", "exe", "bin", "car", "nib", "ttf", "otf", "woff", "woff2",
    ]

    private static let sampleLength = 8192

    package static func mayBeText(_ path: VaultPath, size: Int) -> Bool {
        guard size <= textLimit else { return false }
        return previewExtensions.contains((path.fileName as NSString).pathExtension.lowercased()) == false
    }

    package static func text(from data: Data) -> String? {
        guard data.prefix(sampleLength).contains(0) == false else { return nil }
        if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            return String(data: data.dropFirst(3), encoding: .utf8)
        }
        return String(data: data, encoding: .utf8)
    }
}
