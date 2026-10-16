import Foundation

package struct ToggleTodoUseCase: Sendable {
    let files: any VaultFileStore
    let index: any SearchIndex
    let save: SaveNoteUseCase

    package func execute(_ todo: TodoItem) async throws -> NoteDocument? {
        guard let summary = try await index.summary(id: todo.noteID) else { return nil }
        let document = try NoteCodec.decode(try await files.read(summary.path))
        var lines = document.body.components(separatedBy: "\n")
        guard lines.indices.contains(todo.line), let parsed = TodoLinePolicy.parse(lines[todo.line]), parsed.text == todo.text,
              let toggled = TodoLinePolicy.toggle(lines[todo.line]) else { return nil }
        lines[todo.line] = toggled
        return try await save.execute(document, header: document.header, body: lines.joined(separator: "\n")).document
    }
}
