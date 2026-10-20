import Foundation

package struct BacklinksUseCase: Sendable {
    static let contextLength = 160

    let files: any VaultFileStore
    let index: any SearchIndex

    package func execute(for path: VaultPath) async throws -> [Backlink] {
        var result: [Backlink] = []
        for note in try await index.notesLinking(to: path.stem) where note.path != path {
            guard let document = try? NoteCodec.decode(try await files.read(note.path)) else { continue }
            let line = MarkdownText.proseLines(of: document.body).first { MarkdownNoteLinkPolicy.mentions($0, stem: path.stem) }
            result.append(Backlink(note: note, context: line.map { Self.context(of: $0.text) } ?? ""))
        }
        return result
    }

    static func context(of line: String) -> String {
        let text = PreviewPolicy.plainText(of: line)
        guard text.count > contextLength else { return text }
        return String(text.prefix(contextLength)).trimmingCharacters(in: .whitespaces) + "…"
    }
}
