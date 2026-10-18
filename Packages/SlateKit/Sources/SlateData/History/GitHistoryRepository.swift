import Foundation
import SlateDomain

actor GitHistoryRepository: HistoryRepository {
    static let excludes = [".DS_Store", "*.icloud", "*.slate-tmp", ".trash/", ".obsidian/", ".git"]
    static let identity = ["-c", "user.name=Slate", "-c", "user.email=slate@localhost"]
    static let largeFileLimit = 50 * 1024 * 1024
    static let forcePushMarker = "slate-force-push"

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
        try writeExcludes()
    }

    private func writeExcludes() throws {
        let info = gitDirectory.appendingPathComponent("info", isDirectory: true)
        try FileManager.default.createDirectory(at: info, withIntermediateDirectories: true)
        let large = Self.largeFiles(in: workTree).map { "/" + Self.escaped($0) }
        try ((Self.excludes + large).joined(separator: "\n") + "\n").write(to: info.appendingPathComponent("exclude"), atomically: true, encoding: .utf8)
    }

    static func largeFiles(in root: URL, limit: Int = largeFileLimit) -> [String] {
        let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey]
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { return [] }
        var found: [String] = []
        let base = root.standardizedFileURL.resolvingSymlinksInPath().pathComponents
        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: Set(keys)), values.isRegularFile == true, (values.fileSize ?? 0) > limit else { continue }
            let components = url.standardizedFileURL.resolvingSymlinksInPath().pathComponents
            guard components.count > base.count else { continue }
            found.append(components.dropFirst(base.count).joined(separator: "/"))
        }
        return found.sorted()
    }

    private static func escaped(_ path: String) -> String {
        var text = ""
        for character in path {
            if "*?[]\\!#".contains(character) { text.append("\\") }
            text.append(character)
        }
        return text
    }

    func snapshot(message: String?) async throws -> Bool {
        try writeExcludes()
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
        let result = try await shell.runData("git", ["show", "\(hash):\(path.rawValue)"], cwd: workTree.path, environment: environment)
        guard result.exitCode == 0 else { throw HistoryError.command("\(path.rawValue) is not in this version.") }
        return result.data
    }

    func push(to remote: String) async throws {
        let marker = gitDirectory.appendingPathComponent(Self.forcePushMarker)
        let force = FileManager.default.fileExists(atPath: marker.path)
        try await git(["push", "-q"] + (force ? ["--force"] : []) + [remote, "HEAD:refs/heads/main"])
        if force {
            try? FileManager.default.removeItem(at: marker)
        }
    }

    func changes(in folder: FolderPath?, limit: Int) async throws -> [SnapshotChange] {
        var arguments = ["log", "-n", "\(limit)", "--format=\(GitChangesParser.format)", "--name-status", "-M"]
        if let folder {
            arguments += ["--", folder.rawValue]
        }
        let result = try await run(arguments, tolerating: [128])
        guard result.exitCode == 0 else { return [] }
        return GitChangesParser.changes(from: result.stdout)
    }

    func clear(_ folder: FolderPath?) async throws {
        try await ensureRepository()
        let head = try await run(["rev-parse", "--verify", "-q", "HEAD"], tolerating: [1])
        guard head.exitCode == 0 else { return }
        _ = try await snapshot(message: nil)
        if let folder {
            try await rewrite(removing: folder)
            _ = try await snapshot(message: "history of \(folder.rawValue) cleared")
        } else {
            let tree = try await git(["write-tree"]).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            let commit = try await git(Self.identity + ["commit-tree", tree, "-m", "history cleared"]).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            let ref = try await git(["symbolic-ref", "HEAD"]).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            try await git(["update-ref", ref, commit])
        }
        try await git(["reflog", "expire", "--expire=now", "--all"])
        try await git(["gc", "-q", "--prune=now"])
        try Data().write(to: gitDirectory.appendingPathComponent(Self.forcePushMarker))
    }

    private func rewrite(removing folder: FolderPath) async throws {
        let scratch = gitDirectory.deletingLastPathComponent().appendingPathComponent("history-rewrite", isDirectory: true)
        try? FileManager.default.removeItem(at: scratch)
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: scratch) }
        let copy = scratch.appendingPathComponent("copy.git", isDirectory: true).path
        let plain = ["GIT_TERMINAL_PROMPT": "0", "FILTER_BRANCH_SQUELCH_WARNING": "1"]
        try Self.check(try await shell.run("git", ["clone", "-q", "--bare", "--no-local", gitDirectory.path, copy], cwd: scratch.path, environment: plain))
        let filter = "git rm -r -q --cached --ignore-unmatch -- \(Self.quoted(folder.rawValue))"
        try Self.check(try await shell.run("git", ["--git-dir=\(copy)", "filter-branch", "-f", "-d", scratch.appendingPathComponent("work").path, "--index-filter", filter, "HEAD"], cwd: scratch.path, environment: plain))
        let rewritten = try await shell.run("git", ["--git-dir=\(copy)", "rev-parse", "HEAD"], cwd: scratch.path, environment: plain)
        try Self.check(rewritten)
        let commit = rewritten.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        try await git(["fetch", "-q", copy, "HEAD:refs/slate/rewritten"])
        let ref = try await git(["symbolic-ref", "HEAD"]).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        try await git(["update-ref", ref, commit])
        try await git(["update-ref", "-d", "refs/slate/rewritten"])
    }

    private static func check(_ result: ShellResult) throws {
        guard result.exitCode == 0 else { throw HistoryError.command(result.failureMessage) }
    }

    private static func quoted(_ text: String) -> String {
        "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    func lastSnapshot() async throws -> Snapshot? {
        let result = try await run(["log", "-1", "--format=\(GitLogParser.format)"], tolerating: [128])
        guard result.exitCode == 0 else { return nil }
        return GitLogParser.snapshots(from: result.stdout).first
    }

    func canReach(_ remote: String) async -> Bool {
        let result = try? await shell.run("git", ["ls-remote", "--heads", remote], cwd: workTree.path, environment: ["GIT_TERMINAL_PROMPT": "0", "GIT_SSH_COMMAND": "ssh -o BatchMode=yes -o ConnectTimeout=5"])
        return result?.exitCode == 0
    }

    @discardableResult
    private func git(_ arguments: [String], extra: [String: String] = [:]) async throws -> ShellResult {
        let result = try await run(arguments, extra: extra)
        guard result.exitCode == 0 else { throw HistoryError.command(result.failureMessage) }
        return result
    }

    private var environment: [String: String] {
        [
            "GIT_DIR": gitDirectory.path,
            "GIT_WORK_TREE": workTree.path,
            "GIT_TERMINAL_PROMPT": "0",
        ]
    }

    private func run(_ arguments: [String], tolerating tolerated: Set<Int32> = [], extra: [String: String] = [:]) async throws -> ShellResult {
        try await shell.run("git", arguments, cwd: workTree.path, environment: environment.merging(extra) { _, new in new }, tolerating: tolerated)
    }
}
