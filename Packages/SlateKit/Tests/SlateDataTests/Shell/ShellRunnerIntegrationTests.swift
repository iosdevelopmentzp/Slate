import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateData

@Suite(.tags(.integration)) struct ShellRunnerIntegrationTests {
    @Test func runReturnsOutputAndRecordsTheCommand() async throws {
        let recorder = SpyCommandRecorder()
        let runner = ShellRunner(recorder: recorder)

        let result = try await runner.run("echo", ["hello"], cwd: nil)

        #expect(result.stdout == "hello\n")
        #expect(result.exitCode == 0)
        #expect(recorder.records.map(\.command) == ["echo hello"])
        #expect(recorder.records.first?.isFailure == false)
    }

    @Test func failingCommandIsRecordedAsFailure() async throws {
        let recorder = SpyCommandRecorder()
        let runner = ShellRunner(recorder: recorder)

        let result = try await runner.run("sh", ["-c", "echo broken >&2; exit 3"], cwd: nil)

        #expect(result.exitCode == 3)
        #expect(result.failureMessage == "broken")
        #expect(recorder.records.first?.isFailure == true)
        #expect(recorder.records.first?.outputTail == ["broken"])
    }

    @Test func streamDeliversEveryLine() async throws {
        let recorder = SpyCommandRecorder()
        let runner = ShellRunner(recorder: recorder)
        let lines = CallbackRecorder<String>()

        let status = try await runner.stream("sh", ["-c", "echo one; echo two"], cwd: nil) { lines.append($0) }

        #expect(status == 0)
        #expect(lines.values == ["one", "two"])
        #expect(recorder.records.first?.outputTail == ["one", "two"])
    }
}
