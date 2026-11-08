import Foundation
import SlateDomain

struct GitAppUpdater: AppUpdating {
    static let git = "/usr/bin/git"

    let shell: ShellRunner
    let folder: URL

    static var defaultFolder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("Slate/update", isDirectory: true)
    }

    private var statusURL: URL { folder.appendingPathComponent("status.json") }
    private var lockURL: URL { folder.appendingPathComponent("update.lock") }
    private var logURL: URL { folder.appendingPathComponent("update.log") }

    func installed() async -> InstalledBuild? {
        (try? Data(contentsOf: folder.appendingPathComponent("installed.json"))).flatMap(UpdateFileParser.installed)
    }

    func newCommits(for build: InstalledBuild) async throws -> [UpdateCommit] {
        let remote = "origin/" + build.branch
        try await fetch(build)
        let ancestor = try await shell.run(Self.git, ["-C", build.source, "merge-base", "--is-ancestor", build.commit, remote], cwd: nil, tolerating: [1, 128])
        guard ancestor.exitCode == 0 else { return [] }
        let log = try await shell.run(Self.git, ["-C", build.source, "log", "--format=%h%x1f%s", "\(build.commit)..\(remote)"], cwd: nil)
        return UpdateFileParser.commits(log.stdout)
    }

    func start(_ build: InstalledBuild) async throws {
        try await fetch(build)
        let reset = try await shell.run(Self.git, ["-C", build.source, "reset", "--quiet", "--hard", "origin/" + build.branch], cwd: nil)
        guard reset.exitCode == 0 else { throw UpdateError.fetchFailed(reset.stderr.trimmingCharacters(in: .whitespacesAndNewlines)) }
        let script = URL(fileURLWithPath: build.source).appendingPathComponent("Scripts/update.sh").path
        guard FileManager.default.isExecutableFile(atPath: script) else { throw UpdateError.noScript(script) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let command = "/usr/bin/nohup \(quoted(script)) > \(quoted(logURL.path)) 2>&1 &"
        let result = try await shell.run("/bin/zsh", ["-c", command], cwd: build.source)
        guard result.exitCode == 0 else { throw UpdateError.startFailed(result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }

    func status() async -> UpdateStatus? {
        (try? Data(contentsOf: statusURL)).flatMap(UpdateFileParser.status)
    }

    func isRunning() async -> Bool {
        guard let text = try? String(contentsOf: lockURL, encoding: .utf8), let pid = Int32(text.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
        return kill(pid, 0) == 0
    }

    func clearStatus() async {
        try? FileManager.default.removeItem(at: statusURL)
    }

    func log() async -> String {
        (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
    }

    private func fetch(_ build: InstalledBuild) async throws {
        let result = try await shell.run(Self.git, ["-C", build.source, "fetch", "--quiet", "origin", build.branch], cwd: nil)
        guard result.exitCode == 0 else { throw UpdateError.fetchFailed(result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }

    private func quoted(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
