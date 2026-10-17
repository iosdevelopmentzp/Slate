import Foundation
import SlateDomain
import UniformTypeIdentifiers

enum NoteDrag {
    static func provider(id: NoteID, fileURL: URL) -> NSItemProvider {
        let provider = NSItemProvider(object: fileURL as NSURL)
        provider.suggestedName = fileURL.deletingPathExtension().lastPathComponent
        provider.registerDataRepresentation(forTypeIdentifier: UTType.utf8PlainText.identifier, visibility: .ownProcess) { completion in
            completion(Data(NoteDragPayload.text(for: id).utf8), nil)
            return nil
        }
        return provider
    }
}
