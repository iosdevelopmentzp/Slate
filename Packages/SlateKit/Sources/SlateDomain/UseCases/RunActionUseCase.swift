import Foundation

package struct RunActionUseCase: Sendable {
    let runner: any ActionRunning
    let append: AppendToNoteUseCase

    package func execute(_ action: ActionDefinition, on document: NoteDocument, vault: URL) async throws -> ActionResult {
        var result = try await runner.run(action.command, environment: ActionEnvironmentPolicy.environment(for: document, vault: vault), workingDirectory: vault)
        if action.output == .appendToNote, result.succeeded, result.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            result.appended = try await append.execute(ActionEnvironmentPolicy.logBlock(result.output), to: .path(document.path), section: nil)
        }
        return result
    }
}
