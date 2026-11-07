import Foundation
import SlateDomain

enum FileHeaderMapper {
    static func lines(for document: NoteDocument) -> [String]? {
        if let opaque = document.opaqueHeader {
            let lines = opaque.components(separatedBy: "\n").map { $0.hasSuffix("\r") ? String($0.dropLast()) : $0 }
            let inner = lines.drop { $0 == "---" }.prefix { $0 != "---" }
            let shown = Array(inner)
            return shown.isEmpty ? nil : shown
        }
        let unknown = document.header.unknownLines
        return unknown.isEmpty ? nil : unknown
    }
}
