import Foundation
import SlateMocks
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct HistoryUseCaseTests {
    private let keyValues = InMemoryKeyValueStore()
    private let ports: Ports
    private let spies: PortSpies

    init() {
        (ports, spies) = Ports.spies(keyValues: keyValues)
    }

    @Test func snapshotCommitsWithoutAPushWhenNoRemoteIsSet() async throws {
        let outcome = try await UseCases(ports: ports).snapshot.execute()

        #expect(outcome == SnapshotOutcome(committed: true, push: .notConfigured))
        #expect(spies.history.calls == [.ensure, .snapshot(nil)])
    }

    @Test func snapshotPushesToTheRemote() async throws {
        HistorySettings(remote: "git@example.com:me/notes.git").save(to: keyValues)

        let outcome = try await UseCases(ports: ports).snapshot.execute()

        #expect(outcome.push == .pushed)
        #expect(spies.history.calls.last == .push("git@example.com:me/notes.git"))
    }

    @Test func aFailedPushIsReportedNotThrown() async throws {
        HistorySettings(remote: "origin").save(to: keyValues)
        spies.history.pushError = .scripted("no network")

        let outcome = try await UseCases(ports: ports).snapshot.execute()

        #expect(outcome.committed)
        guard case .failed = outcome.push else {
            Issue.record("expected a failed push")
            return
        }
    }

    @Test func historyOffOrGitMissingDoesNothing() async throws {
        HistorySettings(isEnabled: false).save(to: keyValues)
        #expect(try await UseCases(ports: ports).snapshot.execute().committed == false)

        HistorySettings().save(to: keyValues)
        spies.history.available = false
        #expect(try await UseCases(ports: ports).snapshot.execute().committed == false)
        #expect(spies.history.calls.isEmpty)
    }

    @Test func restoreWritesTheOldBodyAndKeepsTheIDAndTitle() async throws {
        let path = VaultPath(rawValue: "Notes/A.md")
        spies.files.seed(path, NoteText.make(id: "a", title: "A", body: "new text"))
        let snapshot = Snapshot(hash: "abc1234", date: Date(), message: "snapshot")
        spies.history.seed(snapshot, of: path, text: NoteText.make(id: "old", title: "Old title", body: "old text"))

        let result = try await UseCases(ports: ports).restoreVersion.execute(snapshot, of: path)

        let restored = try #require(result.document)
        #expect(restored.body == "old text")
        #expect(restored.header.id == NoteID(rawValue: "a"))
        #expect(restored.title == "A")
        #expect(spies.history.calls.contains(.snapshot("before restore: Notes/A.md")))
    }

    @Test func purgeEmptiesOldItems() async throws {
        let old = TrashItem(path: VaultPath(rawValue: "Inbox/Old.md"), originalPath: VaultPath(rawValue: "Inbox/Old.md"), trashedAt: spies.clock.current.addingTimeInterval(-40 * 86_400))
        let fresh = TrashItem(path: VaultPath(rawValue: "Inbox/New.md"), originalPath: VaultPath(rawValue: "Inbox/New.md"), trashedAt: spies.clock.current)
        spies.trash.seed(old)
        spies.trash.seed(fresh)

        let count = try await UseCases(ports: ports).purgeTrash.execute()

        #expect(count == 1)
        #expect(spies.trash.calls == [.delete(old.path)])
    }

    @Test func purgeUsesTheRetentionSetting() async throws {
        keyValues.set(7, forKey: PurgeTrashUseCase.retentionKey)
        spies.trash.seed(TrashItem(path: VaultPath(rawValue: "Inbox/A.md"), originalPath: VaultPath(rawValue: "Inbox/A.md"), trashedAt: spies.clock.current.addingTimeInterval(-8 * 86_400)))

        #expect(try await UseCases(ports: ports).purgeTrash.execute() == 1)
    }
}
