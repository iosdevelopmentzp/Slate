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
    }
}
