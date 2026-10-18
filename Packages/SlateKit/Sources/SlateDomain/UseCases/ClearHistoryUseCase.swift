import Foundation

package struct ClearHistoryUseCase: Sendable {
    let history: any HistoryRepository

    package func execute(_ folder: FolderPath?) async throws {
        guard await history.isAvailable() else { throw HistoryError.gitMissing }
        try await history.clear(folder)
    }
}
