import Foundation
import SlateDomain

struct SystemChecks: SystemChecking {
    let root: URL
    let indexURL: URL
    let shell: ShellRunner

    func checks() async -> [DoctorCheck] {
        var checks: [DoctorCheck] = []
        let reachable = FileManager.default.isWritableFile(atPath: root.path)
        checks.append(DoctorCheck(id: "vault", title: "Notes folder", isOK: reachable, detail: reachable ? root.path : "Slate cannot write to \(root.path). Check the folder in Finder."))
        let git = try? await shell.run("git", ["--version"], cwd: nil)
        let gitOK = git?.exitCode == 0
        checks.append(DoctorCheck(id: "git", title: "Git", isOK: gitOK, detail: gitOK ? (git?.stdout.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") : "Git is not installed. Run xcode-select --install in Terminal."))
        let capture = FileManager.default.isExecutableFile(atPath: "/usr/sbin/screencapture")
        checks.append(DoctorCheck(id: "screencapture", title: "Screenshots", isOK: capture, detail: capture ? "screencapture is available" : "/usr/sbin/screencapture is missing."))
        let size = (try? FileManager.default.attributesOfItem(atPath: indexURL.path)[.size] as? NSNumber)?.int64Value ?? 0
        let modified = try? FileManager.default.attributesOfItem(atPath: indexURL.path)[.modificationDate] as? Date
        let detail = ByteCountFormatter.string(fromByteCount: size, countStyle: .file) + (modified.map { ", changed \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "")
        checks.append(DoctorCheck(id: "index", title: "Search data", isOK: size > 0, detail: detail))
        return checks
    }
}
