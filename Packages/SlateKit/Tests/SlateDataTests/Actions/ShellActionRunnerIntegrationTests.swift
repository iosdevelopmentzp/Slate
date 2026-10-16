import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateData

@Suite(.tags(.integration)) struct ShellActionRunnerIntegrationTests {
    @Test func commandSeesTheEnvironment() async throws {
        let folder = try TemporaryDirectory()
        let runner = ShellActionRunner(shell: ShellRunner(recorder: SpyCommandRecorder()))

        let result = try await runner.run("printf '%s|%s' \"$SLATE_TICKET\" \"$(pwd)\"", environment: ["SLATE_TICKET": "ABC-1"], workingDirectory: folder.url)

        #expect(result.exitCode == 0)
        #expect(result.output.hasPrefix("ABC-1|"))
    }

    @Test func failureKeepsTheExitCode() async throws {
        let runner = ShellActionRunner(shell: ShellRunner(recorder: SpyCommandRecorder()))

        let result = try await runner.run("echo bad; exit 3", environment: [:], workingDirectory: URL(fileURLWithPath: NSTemporaryDirectory()))

        #expect(result.exitCode == 3)
        #expect(result.output == "bad")
    }
}
