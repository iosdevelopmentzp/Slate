import Foundation
import SlateDomain

package actor ShellRunner {
    nonisolated let recorder: any CommandRecording

    static let outputTailCount = 40
    private static let extraPath = ["/opt/homebrew/bin", "/usr/local/bin"]
    fileprivate static let blockingQueue = DispatchQueue(label: "Slate.ShellRunner", attributes: .concurrent)

    package init(recorder: any CommandRecording) {
        self.recorder = recorder
    }

    nonisolated package func run(_ executable: String, _ arguments: [String], cwd: String?, environment: [String: String] = [:], tolerating tolerated: Set<Int32> = []) async throws -> ShellResult {
        let command = CommandFormatter.displayCommand(executable, arguments)
        do {
            let result = try await withCheckedThrowingContinuation { continuation in
                Self.blockingQueue.async {
                    continuation.resume(with: Result { try Self.runBlocking(executable, arguments, cwd: cwd, environment: environment) })
                }
            }
            recorder.record(CommandRecord(command: command, cwd: cwd, exitCode: result.exitCode, error: nil, outputTail: Array(result.lines.suffix(Self.outputTailCount)), toleratedExitCodes: tolerated))
            return result
        } catch {
            recorder.record(CommandRecord(command: command, cwd: cwd, exitCode: nil, error: error.localizedDescription, outputTail: []))
            throw error
        }
    }

    func stream(
        _ executable: String,
        _ arguments: [String],
        cwd: String?,
        environment: [String: String] = [:],
        onLine: @escaping @Sendable (String) -> Void
    ) async throws -> Int32 {
        let command = CommandFormatter.displayCommand(executable, arguments)
        let process = Self.makeProcess(executable, arguments, cwd: cwd, environment: environment)
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
        } catch {
            recorder.record(CommandRecord(command: command, cwd: cwd, exitCode: nil, error: error.localizedDescription, outputTail: []))
            throw error
        }
        let handle = ProcessHandle(process)
        var tail: [String] = []
        do {
            let status = try await withTaskCancellationHandler {
                for try await line in pipe.fileHandleForReading.bytes.lines {
                    tail.append(line)
                    if tail.count > Self.outputTailCount {
                        tail.removeFirst()
                    }
                    onLine(line)
                }
                process.waitUntilExit()
                return process.terminationStatus
            } onCancel: {
                handle.terminate()
            }
            recorder.record(CommandRecord(command: command, cwd: cwd, exitCode: status, error: Task.isCancelled ? "Cancelled" : nil, outputTail: tail))
            return status
        } catch {
            recorder.record(CommandRecord(command: command, cwd: cwd, exitCode: nil, error: error.localizedDescription, outputTail: tail))
            throw error
        }
    }

    private static func runBlocking(_ executable: String, _ arguments: [String], cwd: String?, environment: [String: String]) throws -> ShellResult {
        let process = makeProcess(executable, arguments, cwd: cwd, environment: environment)
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        try process.run()
        let stderrReader = DataReader(stderrPipe.fileHandleForReading)
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrReader.wait()
        process.waitUntilExit()
        return ShellResult(
            stdout: String(decoding: stdoutData, as: UTF8.self),
            stderr: String(decoding: stderrData, as: UTF8.self),
            exitCode: process.terminationStatus
        )
    }

    private static func makeProcess(_ executable: String, _ arguments: [String], cwd: String?, environment extra: [String: String]) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [executable] + arguments
        var environment = ProcessInfo.processInfo.environment
        let path = environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        environment["PATH"] = (extraPath + [path]).joined(separator: ":")
        environment.merge(extra) { _, new in new }
        process.environment = environment
        if let cwd {
            process.currentDirectoryURL = URL(fileURLWithPath: (cwd as NSString).expandingTildeInPath)
        }
        return process
    }
}

private final class DataReader: @unchecked Sendable {
    private let semaphore = DispatchSemaphore(value: 0)
    private var data = Data()

    init(_ handle: FileHandle) {
        ShellRunner.blockingQueue.async { [self] in
            data = handle.readDataToEndOfFile()
            semaphore.signal()
        }
    }

    func wait() -> Data {
        semaphore.wait()
        return data
    }
}

private final class ProcessHandle: @unchecked Sendable {
    private let process: Process

    init(_ process: Process) {
        self.process = process
    }

    func terminate() {
        guard process.isRunning else { return }
        process.terminate()
    }
}
