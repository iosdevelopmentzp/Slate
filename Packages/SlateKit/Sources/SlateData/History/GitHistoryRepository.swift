import Foundation
import SlateDomain

actor GitHistoryRepository: HistoryRepository {
    static let excludes = [".DS_Store", "*.icloud", "*.slate-tmp", ".trash/", ".obsidian/", ".git"]
    static let identity = ["-c", "user.name=Slate", "-c", "user.email=slate@localhost"]

    let shell: ShellRunner
    let gitDirectory: URL
    let workTree: URL
    private var available: Bool?

    init(shell: ShellRunner, gitDirectory: URL, workTree: URL) {
        self.shell = shell
        self.gitDirectory = gitDirectory
        self.workTree = workTree
    }

    func isAvailable() async -> Bool {
        if let available { return available }
        let result = try? await shell.run("git", ["--version"], cwd: nil)
        let found = result?.exitCode == 0
        available = found
        return found
    }

    func ensureRepository() async throws {
        guard await isAvailable() else { throw HistoryError.gitMissing }
        let head = gitDirectory.appendingPathComponent("HEAD")
        if FileManager.default.fileExists(atPath: head.path) == false {
            try FileManager.default.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
            try await git(["init", "-q"])
            for setting in [["core.autocrlf", "false"], ["core.quotepath", "false"], ["gc.auto", "0"]] {
                try await git(["config"] + setting)
            }
        }
        let info = gitDirectory.appendingPathComponent("info", isDirectory: true)
        try FileManager.default.createDirectory(at: info, withIntermediateDirectories: true)
        try (Self.excludes.joined(separator: "\n") + "\n").write(to: info.appendingPathComponent("exclude"), atomically: true, encoding: .utf8)
    }

    func snapshot(message: String?) async throws -> Bool {
        try await git(["add", "-A"])
        let diff = try await run(["diff", "--cached", "--quiet"], tolerating: [1])
        guard diff.exitCode == 1 else {
            if diff.exitCode == 0 { return false }
            throw HistoryError.command(diff.failureMessage)
        }
        let names = try await git(["diff", "--cached", "--name-only"])
        let count = names.stdout.split(separator: "\n").count
        try await git(Self.identity + ["commit", "-q", "-m", message ?? "snapshot: \(count) \(count == 1 ? "file" : "files")"])
        return true
    }

    func history(of path: VaultPath) async throws -> [Snapshot] {
        let result = try await run(["log", "--format=\(GitLogParser.format)", "--follow", "--", path.rawValue], tolerating: [128])
        guard result.exitCode == 0 else { return [] }
        return GitLogParser.snapshots(from: result.stdout)
    }

    func contents(of path: VaultPath, at hash: String) async throws -> Data {
        let result = try await git(["show", "\(hash):\(path.rawValue)"])
        return Data(result.stdout.utf8)
    }

    func push(to remote: String) async throws {
        try await git(["push", "-q", remote, "HEAD:refs/heads/main"])
    }

    func lastSnapshot() async throws -> Snapshot? {
        let result = try await run(["log", "-1", "--format=\(GitLogParser.format)"], tolerating: [128])
        guard result.exitCode == 0 else { return nil }
        return GitLogParser.snapshots(from: result.stdout).first
    }

    @discardableResult
    private func git(_ arguments: [String]) async throws -> ShellResult {
        let result = try await run(arguments)
        guard result.exitCode == 0 else { throw HistoryError.command(result.failureMessage) }
        return result
    }

    private func run(_ arguments: [String], tolerating tolerated: Set<Int32> = []) async throws -> ShellResult {
        try await shell.run("git", arguments, cwd: workTree.path, environment: [
            "GIT_DIR": gitDirectory.path,
            "GIT_WORK_TREE": workTree.path,
            "GIT_TERMINAL_PROMPT": "0",
        ], tolerating: tolerated)
    }
}
