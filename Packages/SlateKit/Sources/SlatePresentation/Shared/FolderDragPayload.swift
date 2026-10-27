import Foundation
import SlateDomain
import UniformTypeIdentifiers

enum FolderDragPayload {
    static let prefix = "slate-folder:"

    static func text(for folder: FolderPath) -> String {
        prefix + folder.rawValue
    }

    static func folder(from text: String) -> FolderPath? {
        guard text.hasPrefix(prefix) else { return nil }
        let raw = String(text.dropFirst(prefix.count))
        return raw.isEmpty ? nil : FolderPath(rawValue: raw)
    }

    static func provider(for folder: FolderPath) -> NSItemProvider {
        let provider = NSItemProvider()
        provider.suggestedName = folder.name
        provider.registerDataRepresentation(forTypeIdentifier: UTType.utf8PlainText.identifier, visibility: .ownProcess) { completion in
            completion(Data(text(for: folder).utf8), nil)
            return nil
        }
        return provider
    }
}
