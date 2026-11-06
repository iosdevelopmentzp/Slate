import Foundation

package struct QuickCaptureUseCase: Sendable {
    let create: CreateNoteUseCase
    let append: AppendToNoteUseCase
    let config: any VaultConfigRepository
    let keyValues: any KeyValueStore
    let importAttachment: ImportAttachmentUseCase

    package func execute(_ input: CaptureInput) async throws -> NoteDocument? {
        guard let document = try await note(for: input) else { return nil }
        guard input.attachments.isEmpty == false else { return document }
        var markdown: [String] = []
        for attachment in input.attachments {
            switch attachment {
            case .image(let data, let fileExtension):
                markdown.append(try await importAttachment.execute(data: data, fileExtension: fileExtension, for: document.path))
            case .file(let url):
                markdown.append(try await importAttachment.execute(files: [url], for: document.path).text)
            }
        }
        return try await append.execute(markdown.joined(separator: "\n\n"), to: .path(document.path), section: nil)
    }

    private func note(for input: CaptureInput) async throws -> NoteDocument? {
        var text = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty, let first = input.attachments.first {
            text = first.isImage ? StemPolicy.untitled : (first.name as NSString).deletingPathExtension
        }
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
