import Foundation
import SlateDomain

struct ScreencaptureTool: ScreenCapturing {
    let shell: ShellRunner

    func capture(_ mode: CaptureMode, to url: URL) async throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        _ = try await shell.run("screencapture", Self.arguments(for: mode, path: url.path), cwd: nil)
    }

    static func arguments(for mode: CaptureMode, path: String) -> [String] {
        switch mode {
        case .region: ["-i", "-x", "-t", "png", path]
        case .window: ["-i", "-W", "-o", "-x", "-t", "png", path]
        }
    }
}
