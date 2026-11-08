import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateData

@Suite(.tags(.integration)) struct GitAppUpdaterIntegrationTests {
    private let root: TemporaryDirectory
    private let shell = ShellRunner(recorder: SpyCommandRecorder())
    private let updater: GitAppUpdater

    init() throws {
        root = try TemporaryDirectory()
        updater = GitAppUpdater(shell: shell, folder: root.url.appendingPathComponent("update"))
    }

    private var remote: String { root.url.appendingPathComponent("remote").path }
    private var source: String { root.url.appendingPathComponent("source").path }

    @discardableResult
    private func git(_ arguments: [String], in directory: String) async throws -> String {
        let result = try await shell.run("/usr/bin/git", ["-c", "user.name=T", "-c", "user.email=t@example.com"] + arguments, cwd: directory)
        #expect(result.exitCode == 0, "\(arguments): \(result.stderr)")
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func commit(_ message: String) async throws -> String {
        try Data(message.utf8).write(to: URL(fileURLWithPath: remote).appendingPathComponent("\(message).txt"))
        try await git(["add", "."], in: remote)
        try await git(["commit", "-q", "-m", message], in: remote)
        return try await git(["rev-parse", "HEAD"], in: remote)
    }

    private func setUp() async throws -> String {
        try FileManager.default.createDirectory(atPath: remote, withIntermediateDirectories: true)
        try await git(["init", "-q", "-b", "main"], in: remote)
        let first = try await commit("first")
        try await git(["clone", "-q", remote, source], in: root.url.path)
        return first
    }

    @Test func newCommitsOnTheRemoteAreListed() async throws {
        let first = try await setUp()
        _ = try await commit("second")
        _ = try await commit("third")

        let commits = try await updater.newCommits(for: InstalledBuild(commit: first, branch: "main", source: source))

        #expect(commits.map(\.subject) == ["third", "second"])
    }

    @Test func anUpToDateOrUnknownBuildHasNothingNew() async throws {
        let first = try await setUp()

        #expect(try await updater.newCommits(for: InstalledBuild(commit: first, branch: "main", source: source)).isEmpty)
        #expect(try await updater.newCommits(for: InstalledBuild(commit: String(repeating: "a", count: 40), branch: "main", source: source)).isEmpty)
    }

    @Test func startBringsTheCloneToTheRemoteBeforeItRunsTheScript() async throws {
        let first = try await setUp()
        let marker = root.url.appendingPathComponent("ran")
        let scripts = URL(fileURLWithPath: remote).appendingPathComponent("Scripts")
        try FileManager.default.createDirectory(at: scripts, withIntermediateDirectories: true)
        let script = scripts.appendingPathComponent("update.sh")
        try Data("#!/bin/zsh\ntouch '\(marker.path)'\n".utf8).write(to: script)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
        _ = try await commit("script")

        try await updater.start(InstalledBuild(commit: first, branch: "main", source: source))

        try await waitUntil { FileManager.default.fileExists(atPath: marker.path) }
    }

    @Test func theStatusAndTheLockAreRead() async throws {
        let folder = root.url.appendingPathComponent("update")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data(#"{"phase": "failed", "startedAt": "2026-11-07T10:00:00Z", "message": "The build failed."}"#.utf8).write(to: folder.appendingPathComponent("status.json"))
        try Data("\(ProcessInfo.processInfo.processIdentifier)".utf8).write(to: folder.appendingPathComponent("update.lock"))

        #expect(await updater.status()?.message == "The build failed.")
        #expect(await updater.isRunning())
        await updater.clearStatus()
        #expect(await updater.status() == nil)
    }
}
