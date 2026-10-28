import Foundation

package enum FileIndexPolicy {
    package static let textLength = 1_000_000
    package static let pdfLimit = 50 * 1024 * 1024
    private static let excerptLength = 160

    package static func isIndexed(_ path: VaultPath) -> Bool {
        path.space != nil
            && path.isNote == false
            && path.fileName.hasPrefix(".") == false
            && path.fileName.hasSuffix(".slate-tmp") == false
            && path.components.contains(where: { $0.hasPrefix(".") }) == false
    }

    package static func readsContent(_ path: VaultPath, size: Int) -> Bool {
        isPDF(path) ? size <= pdfLimit : FileKindPolicy.mayBeText(path, size: size)
    }

    package static func isPDF(_ path: VaultPath) -> Bool {
        (path.fileName as NSString).pathExtension.lowercased() == "pdf"
    }

    package static func trimmed(_ text: String) -> String {
        text.count > textLength ? String(text.prefix(textLength)) : text
    }

    package static func searchable(_ query: SearchQuery) -> Bool {
        query.hasText && query.filters.allSatisfy { if case .space = $0 { true } else { false } } && query.excludedFilters.isEmpty
    }

    package static func hits(in files: [IndexedFile], query: SearchQuery, limit: Int) -> [FileHit] {
        guard searchable(query) else { return [] }
        let words = query.words.map { $0.lowercased() }
        let excluded = query.excludedTerms.map { $0.lowercased() }
        let spaces = query.filters.compactMap { filter -> String? in if case .space(let name) = filter { name.lowercased() } else { nil } }
        let hits = files.compactMap { file -> FileHit? in
            if let space = file.path.space?.rawValue.lowercased(), spaces.isEmpty == false, spaces.contains(space) == false { return nil }
            let haystack = "\(file.path.fileName) \(file.text)".lowercased()
            guard words.allSatisfy(haystack.contains), excluded.contains(where: haystack.contains) == false else { return nil }
            return FileHit(path: file.path, excerpt: excerpt(of: file.text, words: words), rank: 0)
        }
        return Array(hits.sorted { $0.path.rawValue < $1.path.rawValue }.prefix(limit))
    }

    private static func excerpt(of text: String, words: [String]) -> String {
        let lower = text.lowercased()
        guard let word = words.first, let range = lower.range(of: word) else {
            return String(text.prefix(excerptLength)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let offset = lower.distance(from: lower.startIndex, to: range.lowerBound)
        let start = text.index(text.startIndex, offsetBy: max(0, offset - 40))
        let end = text.index(start, offsetBy: excerptLength, limitedBy: text.endIndex) ?? text.endIndex
        return (start > text.startIndex ? "…" : "") + text[start..<end].replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
    }
}
