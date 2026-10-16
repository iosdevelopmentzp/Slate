import Foundation

package struct OpenTargetUseCase: Sendable {
    package enum Outcome: Hashable, Sendable {
        case found(NoteID)
        case created(CreatedNote)
        case missing
    }

    let index: any SearchIndex
    let create: CreateNoteUseCase

    package func execute(_ target: URLCommand.OpenTarget) async throws -> Outcome {
        switch target {
        case .id(let id):
            return try await index.summary(id: id) == nil ? .missing : .found(id)
        case .ticket(let ticket):
            if let found = try await index.notes(withTicket: ticket).first {
                return .found(found.id)
            }
            return .created(try await create.execute(NoteDraft(title: ticket, type: NoteType.task.name, ticket: ticket)))
        case .title(let title):
            let all = try await index.summaries(space: nil)
            let stem = StemPolicy.stem(forTitle: title)
            let found = all.first { StemPolicy.isSame($0.title, title) } ?? all.first { StemPolicy.isSame($0.stem, stem) }
            return found.map { .found($0.id) } ?? .missing
        }
    }
}
