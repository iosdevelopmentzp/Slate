import Foundation

package struct QuickCaptureUseCase: Sendable {
    let create: CreateNoteUseCase
    let append: AppendToNoteUseCase
    let config: any VaultConfigRepository
    let keyValues: any KeyValueStore

    package func execute(_ input: CaptureInput) async throws -> NoteDocument? {
        let text = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else { return nil }
        if input.destination == .today {
            return try await append.execute(text, to: .today, section: nil)
        }
        let lines = text.components(separatedBy: "\n")
        let first = lines.first ?? text
        let rest = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        let type = input.type ?? Self.suggestedType(for: text, settings: TrackerSettings.load(from: keyValues))
        var space = input.space
        if space == nil, type != NoteType.task.name {
            space = try await config.spaces().captureSpace
        }
        let title = TitlePolicy.title(fromBody: first) ?? first
        let body = rest.isEmpty ? "" : rest + "\n"
        return try await create.execute(NoteDraft(title: title, type: type, space: space, body: type == NoteType.task.name && rest.isEmpty ? nil : body)).document
    }

    package static func suggestedType(for text: String, settings: TrackerSettings) -> String {
        TitlePolicy.startsWithTicket(text, ticketPattern: settings.ticketPattern) ? NoteType.task.name : NoteType.defaultName
    }
}
