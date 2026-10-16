import Foundation

package struct AppendToNoteUseCase: Sendable {
    let files: any VaultFileStore
    let index: any SearchIndex
    let save: SaveNoteUseCase
    let create: CreateNoteUseCase
    let ensureDaily: EnsureDailyNoteUseCase
    let clock: any Clock

    package func execute(_ text: String, to target: AppendTarget, section: String?) async throws -> NoteDocument {
        var document = try await resolve(target)
        let content = target == .today && section == nil ? DailyPolicy.logLine(text, at: clock.now(), timeZone: clock.timeZone) : text
        let heading = target == .today ? (section ?? DailyPolicy.logHeading) : section
        for _ in 0..<3 {
            let body = SectionAppendPolicy.append(content, toSection: heading, in: document.body)
            switch try await save.execute(document, header: document.header, body: body) {
            case .saved(let saved), .unchanged(let saved):
                return saved
            case .conflict:
                document = try NoteCodec.decode(try await files.read(document.path))
            }
        }
        throw VaultError.alreadyExists(document.path.rawValue)
    }

    private func resolve(_ target: AppendTarget) async throws -> NoteDocument {
        switch target {
        case .today:
            return try await ensureDaily.execute().document
        case .path(let path):
            return try NoteCodec.decode(try await files.read(path))
        case .id(let id):
            guard let summary = try await index.summary(id: id) else { throw VaultError.notFound(VaultPath(rawValue: id.rawValue)) }
            return try NoteCodec.decode(try await files.read(summary.path))
        case .ticket(let ticket):
            if let summary = try await index.notes(withTicket: ticket).first {
                return try NoteCodec.decode(try await files.read(summary.path))
            }
            return try await create.execute(NoteDraft(title: ticket, type: NoteType.task.name, ticket: ticket)).document
        }
    }
}
