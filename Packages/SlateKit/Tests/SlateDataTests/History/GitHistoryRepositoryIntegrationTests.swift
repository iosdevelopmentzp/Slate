import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateData

@Suite(.tags(.integration)) struct GitHistoryRepositoryIntegrationTests {
    private let vault: TemporaryDirectory
    private let support: TemporaryDirectory
    private let repository: GitHistoryRepository

    init() throws {
        vault = try TemporaryDirectory()
        support = try TemporaryDirectory()
        repository = GitHistoryRepository(shell: ShellRunner(recorder: SpyCommandRecorder()), gitDirectory: support.url.appendingPathComponent("history.git"), workTree: vault.url)
    }

    @Test func snapshotsLiveOutsideTheVault() async throws {
        _ = try vault.write("one", to: "Notes/A.md")
        _ = try vault.write("ignored", to: ".trash/Old.md")

        try await repository.ensureRepository()
        #expect(try await repository.snapshot(message: nil))

        #expect(FileManager.default.fileExists(atPath: vault.path(".git")) == false)
        #expect(FileManager.default.fileExists(atPath: support.path("history.git/HEAD")))
        #expect(try await repository.snapshot(message: nil) == false)
    }

    @Test func historyOfAFileAndItsOldContents() async throws {
        let path = VaultPath(rawValue: "Notes/A.md")
        _ = try vault.write("first", to: path.rawValue)
        try await repository.ensureRepository()
        _ = try await repository.snapshot(message: nil)
        _ = try vault.write("second", to: path.rawValue)
        _ = try await repository.snapshot(message: nil)

        let history = try await repository.history(of: path)

        #expect(history.count == 2)
        #expect(history.first?.message == "snapshot: 1 file")
        let old = try await repository.contents(of: path, at: history[1].hash)
        #expect(String(decoding: old, as: UTF8.self) == "first")
        #expect(try await repository.lastSnapshot()?.hash == history[0].hash)
    }

    @Test func binaryVersionsComeBackByteForByte() async throws {
        let path = VaultPath(rawValue: "MyApp/Task/screen.png")
        let bytes = Data([0x89, 0x50, 0x4E, 0x47, 0x00, 0xFF, 0xFE, 0x0A, 0x00, 0x80])
        try FileManager.default.createDirectory(at: vault.url.appendingPathComponent("MyApp/Task"), withIntermediateDirectories: true)
        try bytes.write(to: vault.url.appendingPathComponent(path.rawValue))
        try await repository.ensureRepository()
        _ = try await repository.snapshot(message: nil)

        let hash = try #require(try await repository.history(of: path).first?.hash)

        #expect(try await repository.contents(of: path, at: hash) == bytes)
    }

    @Test func filesAboveTheLimitStayOutOfTheHistory() async throws {
        _ = try vault.write("small", to: "Notes/A.md")
        _ = try vault.write(String(repeating: "x", count: 2_000), to: "Notes/big.log")

        #expect(GitHistoryRepository.largeFiles(in: vault.url, limit: 1_000) == ["Notes/big.log"])
        #expect(GitHistoryRepository.largeFiles(in: vault.url).isEmpty)
    }

    @Test func changesListEveryVersionOfAFolderWithItsFiles() async throws {
        _ = try vault.write("one", to: "MyApp/Plan.md")
        _ = try vault.write("other", to: "Notes/B.md")
        try await repository.ensureRepository()
        _ = try await repository.snapshot(message: nil)
        _ = try vault.write("two", to: "MyApp/Plan.md")
        _ = try vault.write("log", to: "MyApp/crash.log")
        _ = try await repository.snapshot(message: "agent: log_progress Plan")
        try FileManager.default.removeItem(at: vault.url.appendingPathComponent("MyApp/crash.log"))
        _ = try vault.write("more", to: "Notes/B.md")
        _ = try await repository.snapshot(message: "version: done")

        let changes = try await repository.changes(in: FolderPath(rawValue: "MyApp"), limit: 10)

        #expect(changes.map(\.snapshot.message) == ["version: done", "agent: log_progress Plan", "snapshot: 2 files"])
        #expect(changes[0].files == [ChangedFile(path: VaultPath(rawValue: "MyApp/crash.log"), kind: .removed)])
        #expect(Set(changes[1].files) == [ChangedFile(path: VaultPath(rawValue: "MyApp/Plan.md"), kind: .changed), ChangedFile(path: VaultPath(rawValue: "MyApp/crash.log"), kind: .added)])
        #expect(try await repository.changes(in: nil, limit: 1).count == 1)
    }

    @Test func clearingEverythingKeepsOnlyTheCurrentState() async throws {
        let path = VaultPath(rawValue: "Notes/A.md")
        _ = try vault.write("first", to: path.rawValue)
        try await repository.ensureRepository()
        _ = try await repository.snapshot(message: nil)
        _ = try vault.write("second", to: path.rawValue)

        try await repository.clear(nil)

        let history = try await repository.history(of: path)
        #expect(history.map(\.message) == ["history cleared"])
        #expect(String(decoding: try await repository.contents(of: path, at: history[0].hash), as: UTF8.self) == "second")
        #expect(FileManager.default.fileExists(atPath: support.path("history.git/\(GitHistoryRepository.forcePushMarker)")))
    }

    @Test func clearingAFolderKeepsTheHistoryOfTheOthers() async throws {
        let project = VaultPath(rawValue: "My App/Plan.md")
        let other = VaultPath(rawValue: "Notes/B.md")
        _ = try vault.write("one", to: project.rawValue)
        _ = try vault.write("b1", to: other.rawValue)
        try await repository.ensureRepository()
        _ = try await repository.snapshot(message: nil)
        _ = try vault.write("two", to: project.rawValue)
        _ = try vault.write("b2", to: other.rawValue)
        _ = try await repository.snapshot(message: nil)

        try await repository.clear(FolderPath(rawValue: "My App"))

        #expect(try String(contentsOfFile: vault.path(project.rawValue), encoding: .utf8) == "two")
        #expect(try await repository.snapshot(message: nil) == false)
        #expect(try await repository.history(of: project).map(\.message) == ["history of My App cleared"])
        #expect(try await repository.history(of: other).count == 2)
        let latest = try #require(try await repository.history(of: project).first)
        #expect(String(decoding: try await repository.contents(of: project, at: latest.hash), as: UTF8.self) == "two")
    }

    @Test func pushAfterClearingReplacesTheRemoteHistory() async throws {
        let remote = try TemporaryDirectory()
        let shell = ShellRunner(recorder: SpyCommandRecorder())
        _ = try await shell.run("git", ["init", "-q", "--bare", remote.url.path], cwd: nil)
        _ = try vault.write("first", to: "Notes/A.md")
        try await repository.ensureRepository()
        _ = try await repository.snapshot(message: nil)
        try await repository.push(to: remote.url.path)
        _ = try vault.write("second", to: "Notes/A.md")
        try await repository.clear(nil)

        try await repository.push(to: remote.url.path)

        let log = try await shell.run("git", ["--git-dir", remote.url.path, "log", "--format=%s", "main"], cwd: nil)
        #expect(log.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "history cleared")
        #expect(FileManager.default.fileExists(atPath: support.path("history.git/\(GitHistoryRepository.forcePushMarker)")) == false)
    }

    @Test func emptyRepositoryHasNoHistory() async throws {
        try await repository.ensureRepository()

        #expect(try await repository.history(of: VaultPath(rawValue: "Notes/A.md")).isEmpty)
        #expect(try await repository.lastSnapshot() == nil)
    }

    @Test func pushReachesABareRemote() async throws {
        let remote = try TemporaryDirectory()
        let shell = ShellRunner(recorder: SpyCommandRecorder())
        _ = try await shell.run("git", ["init", "-q", "--bare", remote.url.path], cwd: nil)
        _ = try vault.write("x", to: "Notes/A.md")
        try await repository.ensureRepository()
        _ = try await repository.snapshot(message: nil)

        try await repository.push(to: remote.url.path)

        let log = try await shell.run("git", ["--git-dir", remote.url.path, "log", "--oneline", "main"], cwd: nil)
        #expect(log.exitCode == 0)
        #expect(log.stdout.contains("snapshot"))
        #expect(await repository.lastPushedHash() == (try await repository.lastSnapshot())?.hash)
    }

    @Test func renameChangesOnlyTheMessageOfTheLastSnapshot() async throws {
        _ = try vault.write("x", to: "Notes/A.md")
        try await repository.ensureRepository()
        _ = try await repository.snapshot(message: "agent: append_to_note A")
        _ = try vault.write("y", to: "Notes/B.md")

        try await repository.renameLastSnapshot(to: "version: end of session")

        let versions = try await repository.history(of: VaultPath(rawValue: "Notes/A.md"))
        #expect(versions.map(\.message) == ["version: end of session"])
        #expect(try await repository.history(of: VaultPath(rawValue: "Notes/B.md")).isEmpty)
        #expect(await repository.lastPushedHash() == nil)
    }
}
