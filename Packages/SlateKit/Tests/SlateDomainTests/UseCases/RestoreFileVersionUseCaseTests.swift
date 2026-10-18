import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct RestoreFileVersionUseCaseTests {
    @Test func aFileVersionIsWrittenBackAfterAVersionOfTheCurrentFile() async throws {
        let (ports, spies) = Ports.spies()
        let path = VaultPath(rawValue: "MyApp/Task/state.json")
        let old = Snapshot(hash: "abc1234", date: .now, message: "snapshot: 1 file")
        spies.files.seed(path, "{\"new\":1}")
        spies.history.seed(old, of: path, text: "{\"old\":1}")

        try await UseCases(ports: ports).restoreFileVersion.execute(old, of: path)

        #expect(spies.files.text(at: path) == "{\"old\":1}")
        #expect(spies.history.calls.prefix(2) == [.ensure, .snapshot("before restore: MyApp/Task/state.json")])
    }
}
