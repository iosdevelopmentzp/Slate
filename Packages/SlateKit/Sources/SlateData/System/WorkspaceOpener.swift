import AppKit
import SlateDomain

struct WorkspaceOpener: WorkspaceOpening {
    let quickLook = QuickLookPresenter()
    let shell: ShellRunner

    func open(_ url: URL) async {
        await MainActor.run {
            _ = NSWorkspace.shared.open(url)
        }
    }

    func reveal(_ url: URL) async {
        await MainActor.run {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    func markUp(_ url: URL) async {
        await MainActor.run {
            guard let preview = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Preview") else {
                _ = NSWorkspace.shared.open(url)
                return
            }
            NSWorkspace.shared.open([url], withApplicationAt: preview, configuration: NSWorkspace.OpenConfiguration())
        }
    }

    func quickLook(_ url: URL) async {
        await quickLook.present(url)
    }

    func openCode(_ path: String, line: Int?, in roots: [URL]) async -> Bool {
        guard let url = await Task.detached(operation: { CodeFileFinder.find(path, in: roots) }).value else { return false }
        if let line, let result = try? await shell.run("/usr/bin/xed", ["--line", String(line), url.path], cwd: nil), result.exitCode == 0 {
            return true
        }
        await open(url)
        return true
    }
}
