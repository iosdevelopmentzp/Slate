import Foundation
import SlateDomain

struct GitRepositoryInspector: RepositoryInspecting {
    let shell: ShellRunner

    func inspect(_ directory: URL) async -> RepositoryInfo? {
        let path = directory.standardizedFileURL.path
        guard let paths = try? await shell.run("git", ["-C", path, "rev-parse", "--show-toplevel", "--path-format=absolute", "--git-common-dir"], cwd: nil),
              paths.exitCode == 0
        else { return nil }
        let lines = paths.stdout.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let root = lines.first, root.isEmpty == false else { return nil }
        let common = lines.count > 1 ? URL(fileURLWithPath: lines[1]) : nil
        let mainRoot = common.map { $0.lastPathComponent == ".git" ? $0.deletingLastPathComponent().path : $0.path } ?? root
        let remote = try? await shell.run("git", ["-C", path, "remote", "get-url", "origin"], cwd: nil, tolerating: [2, 128])
        let branch = try? await shell.run("git", ["-C", path, "branch", "--show-current"], cwd: nil, tolerating: [128])
        return RepositoryInfo(root: root, mainRoot: mainRoot, remote: Self.value(remote), branch: Self.value(branch))
    }

    private static func value(_ result: ShellResult?) -> String? {
        guard let result, result.exitCode == 0 else { return nil }
        let text = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }
}
