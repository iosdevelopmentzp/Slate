import ArgumentParser
import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateCLI

@Suite(.serialized) struct CLICommandsTests {
    private let vault: TemporaryDirectory
    private let support: TemporaryDirectory

    init() throws {
        vault = try TemporaryDirectory()
        support = try TemporaryDirectory()
        for space in ["Inbox", "Tasks", "Notes", "Daily"] {
            try FileManager.default.createDirectory(at: vault.url.appendingPathComponent(space), withIntermediateDirectories: true)
        }
    }

    private func run(_ arguments: [String]) async throws {
        var command = try SlateCommand.parseAsRoot(arguments + ["--vault", vault.url.path, "--support-folder", support.url.path])
        if var async = command as? AsyncParsableCommand {
            try await async.run()
        } else {
            try command.run()
        }
    }

    private func text(_ path: String) throws -> String {
        try String(contentsOf: vault.url.appendingPathComponent(path), encoding: .utf8)
    }

    @Test func newMakesATaskFromATicketTitle() async throws {
        try await run(["new", "ABC-2324 Profile screen leaks memory", "--type", "task"])

        let file = try text("Tasks/ABC-2324 Profile screen leaks memory.md")
        #expect(file.contains("ticket: ABC-2324"))
        #expect(file.contains("branch: feature/ABC-2324-profile-screen-leaks-memory"))
    }

    @Test func appendByTicketAddsUnderTheSection() async throws {
        try await run(["new", "ABC-7 Crash", "--type", "task"])

        try await run(["append", "--ticket", "ABC-7", "--section", "Findings", "The delegate is strong."])

        #expect(try text("Tasks/ABC-7 Crash.md").contains("## Findings\n\nThe delegate is strong.\n"))
    }

    @Test func appendToTodayMakesTheDailyNote() async throws {
        try await run(["append", "--today", "Fixed it"])

        let daily = try FileManager.default.contentsOfDirectory(atPath: vault.path("Daily"))
        #expect(daily.count == 1)
        #expect(try text("Daily/\(daily[0])").contains("Fixed it"))
    }

    @Test func newWithABodyUsesIt() async throws {
        try await run(["new", "Plain", "--space", "Notes", "--body", "hello"])

        #expect(try text("Notes/Plain.md").hasSuffix("---\nhello\n"))
    }

    @Test func pathAndSearchRunWithoutErrors() async throws {
        try await run(["new", "ABC-9 Search me", "--type", "task"])

        try await run(["path", "--ticket", "ABC-9"])
        try await run(["search", "search", "--json"])
        try await run(["list", "--space", "Tasks"])
    }

    @Test func aMissingVaultIsAnError() async throws {
        await #expect(throws: (any Error).self) {
            var command = try SlateCommand.parseAsRoot(["today", "--vault", "/nonexistent/folder"])
            guard var async = command as? AsyncParsableCommand else { return }
            try await async.run()
            _ = command
        }
    }
}
