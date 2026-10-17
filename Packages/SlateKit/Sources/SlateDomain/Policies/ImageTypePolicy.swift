import Foundation

package enum ImageTypePolicy {
    private static let heicBrands: Set<String> = ["heic", "heix", "heim", "heis", "hevc", "hevx", "mif1", "msf1"]

    package static func fileExtension(of data: Data) -> String? {
        let bytes = [UInt8](data.prefix(16))
        guard bytes.count >= 12 else { return nil }
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "png" }
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) { return "jpg" }
        if bytes.starts(with: Array("GIF8".utf8)) { return "gif" }
        if bytes.starts(with: Array("RIFF".utf8)), Array(bytes[8..<12]) == Array("WEBP".utf8) { return "webp" }
        if Array(bytes[4..<8]) == Array("ftyp".utf8), heicBrands.contains(String(decoding: bytes[8..<12], as: UTF8.self)) { return "heic" }
        return nil
    }
}
