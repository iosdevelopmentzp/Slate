import Foundation
import SlateDomain
import Testing
import UniformTypeIdentifiers
@testable import SlatePresentation

@Suite struct NoteDragTests {
    private let id = NoteID(rawValue: "abc")
    private let fileURL = URL(fileURLWithPath: "/vault/Notes/Groceries.md")

    @Test func theProviderCarriesTheFileURLForOtherApps() async throws {
        let provider = NoteDrag.provider(id: id, fileURL: fileURL)

        #expect(provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier))
        #expect(provider.suggestedName == "Groceries")
        let url = try await loadURL(provider)
        #expect(url == fileURL)
    }

    @Test func theProviderCarriesTheNoteIDForSlateItself() async throws {
        let provider = NoteDrag.provider(id: id, fileURL: fileURL)

        let data = try await loadData(provider, type: UTType.utf8PlainText)

        #expect(NoteDragPayload.noteID(from: String(decoding: data, as: UTF8.self)) == id)
    }

    private func loadURL(_ provider: NSItemProvider) async throws -> URL? {
        try await withCheckedThrowingContinuation { continuation in
            _ = provider.loadObject(ofClass: NSURL.self) { object, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (object as? NSURL) as URL?)
                }
            }
        }
    }

    private func loadData(_ provider: NSItemProvider, type: UTType) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            _ = provider.loadDataRepresentation(forTypeIdentifier: type.identifier) { data, error in
                if let data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: error ?? CocoaError(.fileReadUnknown))
                }
            }
        }
    }
}
