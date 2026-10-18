import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct ClearHistoryUseCaseTests {
    @Test func clearsAFolderOrEverything() async throws {
        let (ports, spies) = Ports.spies()
        let useCases = UseCases(ports: ports)

        try await useCases.clearHistory.execute(FolderPath(rawValue: "MyApp"))
        try await useCases.clearHistory.execute(nil)

        #expect(spies.history.calls == [.clear(FolderPath(rawValue: "MyApp")), .clear(nil)])
    }

    @Test func withoutGitNothingIsCleared() async throws {
        let (ports, spies) = Ports.spies()
        spies.history.available = false

        await #expect(throws: HistoryError.gitMissing) {
            try await UseCases(ports: ports).clearHistory.execute(nil)
        }
    }
}
