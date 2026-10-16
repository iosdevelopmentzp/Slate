import Foundation

struct FenceDelimiter: Equatable {
    let marker: Character
    let count: Int
    let language: String

    func closes(_ other: FenceDelimiter) -> Bool {
        marker == other.marker && count >= other.count && language.isEmpty
    }

    static func parse(_ line: String) -> FenceDelimiter? {
        let leading = line.prefix { $0 == " " }
        guard leading.count <= 3 else { return nil }
        let rest = line.dropFirst(leading.count)
        guard let marker = rest.first, marker == "`" || marker == "~" else { return nil }
        let run = rest.prefix { $0 == marker }
        guard run.count >= 3 else { return nil }
        let info = rest.dropFirst(run.count).trimmingCharacters(in: .whitespaces)
        if marker == "`", info.contains("`") { return nil }
        let language = info.split(separator: " ").first.map { $0.lowercased() } ?? ""
        return FenceDelimiter(marker: marker, count: run.count, language: language)
    }
}
