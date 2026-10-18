import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateData

@Suite(.tags(.integration), .serialized) struct FSEventsVaultWatcherIntegrationTests {
    private func first(in stream: AsyncStream<VaultChange>, waiting timeout: Duration = .seconds(5), matching match: @escaping @Sendable (VaultChange) -> Bool) async -> VaultChange? {
        await withTaskGroup(of: VaultChange?.self) { group in
            group.addTask {
                for await change in stream where match(change) {
                    return change
                }
                return nil
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return nil
            }
            let result = await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }

    private func settle() async throws {
        try await Task.sleep(for: .seconds(1))
    }

    @Test func externalEditArrivesAsAPathChange() async throws {
        let folder = try TemporaryDirectory()
        try FileManager.default.createDirectory(at: folder.url.appendingPathComponent("Inbox"), withIntermediateDirectories: true)
        let stream = FSEventsVaultWatcher(root: folder.url, ownWrites: OwnWrites()).changes()
        let expected = VaultChange.paths([VaultPath(rawValue: "Inbox/A.md")])
        try await settle()

        let writer = Task {
            for attempt in 1...3 {
                _ = try? folder.write("hello \(attempt)", to: "Inbox/A.md")
                try? await Task.sleep(for: .seconds(2))
            }
        }
        defer { writer.cancel() }

        #expect(await first(in: stream, waiting: .seconds(8)) { $0 == expected } == expected)
    }

    @Test func newFolderArrivesAsARescan() async throws {
        let folder = try TemporaryDirectory()
        let stream = FSEventsVaultWatcher(root: folder.url, ownWrites: OwnWrites()).changes()

        try FileManager.default.createDirectory(at: folder.url.appendingPathComponent("Reading"), withIntermediateDirectories: true)

        #expect(await first(in: stream) { $0 == .rescan } == .rescan)
    }

    @Test func ownWriteDoesNotArrive() async throws {
        let folder = try TemporaryDirectory()
        try FileManager.default.createDirectory(at: folder.url.appendingPathComponent("Inbox"), withIntermediateDirectories: true)
        let ownWrites = OwnWrites()
        let stream = FSEventsVaultWatcher(root: folder.url, ownWrites: ownWrites).changes()
        let store = FileVaultStore(root: folder.url, ownWrites: ownWrites)
        try await settle()

        _ = try await store.create(VaultPath(rawValue: "Inbox/Own.md"), data: Data("mine".utf8))
        _ = try folder.write("theirs", to: "Inbox/Other.md")

        let change = await first(in: stream) { $0 != .rescan }
        #expect(change == .paths([VaultPath(rawValue: "Inbox/Other.md")]))
    }

    private func reported(_ changes: CallbackRecorder<VaultChange>) -> Set<VaultPath> {
        changes.values.reduce(into: Set<VaultPath>()) { result, change in
            if case .paths(let paths) = change { result.formUnion(paths) }
        }
    }

    private func wait(for condition: @escaping () -> Bool) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(5))
        while condition() == false, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(50))
        }
    }

    @Test func renameReportsBothPathsAndDeleteReportsThePath() async throws {
        let folder = try TemporaryDirectory()
        _ = try folder.write("a", to: "Inbox/A.md")
        let stream = FSEventsVaultWatcher(root: folder.url, ownWrites: OwnWrites()).changes()
        let changes = CallbackRecorder<VaultChange>()
        let consumer = Task {
            for await change in stream {
                changes.append(change)
            }
        }
        defer { consumer.cancel() }
        try await settle()
        let settled = changes.values.count
        let old = VaultPath(rawValue: "Inbox/A.md")
        let new = VaultPath(rawValue: "Inbox/B.md")

        try FileManager.default.moveItem(at: folder.url.appendingPathComponent(old.rawValue), to: folder.url.appendingPathComponent(new.rawValue))
        try await wait { reported(changes).isSuperset(of: [old, new]) }
        let afterRename = changes.values.count
        try FileManager.default.removeItem(at: folder.url.appendingPathComponent(new.rawValue))
        try await wait { changes.values.count > afterRename }

        #expect(Array(changes.values.dropFirst(settled).prefix(afterRename - settled)).allSatisfy { $0 != .rescan })
        #expect(reported(changes).isSuperset(of: [old, new]))
        #expect(changes.values.last == .paths([new]))
    }
}
