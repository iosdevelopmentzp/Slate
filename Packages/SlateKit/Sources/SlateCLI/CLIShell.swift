import Foundation
import SlateData

enum CLIShell {
    static func open(_ url: URL) async throws -> Int32 {
        try await ShellRunner(recorder: NoopRecorder()).run("/usr/bin/open", [url.absoluteString], cwd: nil).exitCode
    }
}
