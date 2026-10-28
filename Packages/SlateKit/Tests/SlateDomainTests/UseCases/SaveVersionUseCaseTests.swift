import Foundation
import SlateMocks
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct SaveVersionUseCaseTests {
    private let keyValues = InMemoryKeyValueStore()
    private let ports: Ports
    private let spies: PortSpies
    private let note = VaultPath(rawValue: "Notes/Groceries.md")

    init() {
        (ports, spies) = Ports.spies(keyValues: keyValues)
    }

    private func seedLast(_ message: String, hash: String = "abc123") {
        spies.history.seed(Snapshot(hash: hash, date: Date(timeIntervalSince1970: 1_000), message: message), of: note, text: "Milk")
    }

    @Test func aChangeSinceTheLastVersionIsCommittedWithTheName() async throws {
        let saved = try await UseCases(ports: ports).saveVersion.execute(name: "end of session")

        #expect(saved)
        #expect(spies.history.calls == [.ensure, .snapshot("version: end of session")])
    }

    @Test func withNoChangeTheLastAgentChangeGetsTheName() async throws {
        spies.history.hasChanges = false
        seedLast("agent: append_to_note Groceries")

        let saved = try await UseCases(ports: ports).saveVersion.execute(name: "end of session")

        #expect(saved)
        #expect(spies.history.calls.last == .rename("version: end of session"))
    }

    @Test func aChangeThatIsNotByAnAgentKeepsItsMessage() async throws {
        spies.history.hasChanges = false
        seedLast("version: before refactor")

        let saved = try await UseCases(ports: ports).saveVersion.execute(name: "end of session")

        #expect(saved == false)
        #expect(spies.history.calls.contains(.rename("version: end of session")) == false)
    }

    @Test func aPushedChangeKeepsItsMessage() async throws {
        HistorySettings(remote: "git@example.com:me/notes.git").save(to: keyValues)
        spies.history.hasChanges = false
        spies.history.pushedHash = "abc123"
        seedLast("agent: append_to_note Groceries")

        let saved = try await UseCases(ports: ports).saveVersion.execute(name: "end of session")

        #expect(saved == false)
        #expect(spies.history.calls.contains(.rename("version: end of session")) == false)
    }

    @Test func withARemoteAndNoKnownPushTheChangeKeepsItsMessage() async throws {
        HistorySettings(remote: "git@example.com:me/notes.git").save(to: keyValues)
        spies.history.hasChanges = false
        seedLast("agent: append_to_note Groceries")

        let saved = try await UseCases(ports: ports).saveVersion.execute(name: "end of session")

        #expect(saved == false)
    }

    @Test func aChangeAfterTheLastPushGetsTheName() async throws {
        HistorySettings(remote: "git@example.com:me/notes.git").save(to: keyValues)
        spies.history.hasChanges = false
        spies.history.pushedHash = "older"
        seedLast("agent: append_to_note Groceries")

        let saved = try await UseCases(ports: ports).saveVersion.execute(name: "end of session")

        #expect(saved)
        #expect(spies.history.calls.last == .rename("version: end of session"))
    }

    @Test func versionsOffSaveNothing() async throws {
        HistorySettings(isEnabled: false).save(to: keyValues)
        seedLast("agent: append_to_note Groceries")

        let saved = try await UseCases(ports: ports).saveVersion.execute(name: "end of session")

        #expect(saved == false)
        #expect(spies.history.calls.isEmpty)
    }
}
