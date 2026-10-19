import Foundation

package struct LogProgressUseCase: Sendable {
    let append: AppendToNoteUseCase
    let clock: any Clock

    package func execute(_ text: String, to path: VaultPath) async throws -> LoggedProgress {
        let entry = TaskLogPolicy.entry(text, at: clock.now(), timeZone: clock.timeZone)
        let document = try await append.execute(entry, to: .path(path), section: TaskLogPolicy.heading)
        return LoggedProgress(document: document, entry: entry)
    }
}
