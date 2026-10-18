import Foundation

package struct LogProgressUseCase: Sendable {
    let append: AppendToNoteUseCase
    let clock: any Clock

    package func execute(_ text: String, to path: VaultPath) async throws -> NoteDocument {
        let entry = TaskLogPolicy.entry(text, at: clock.now(), timeZone: clock.timeZone)
        return try await append.execute(entry, to: .path(path), section: TaskLogPolicy.heading)
    }
}
