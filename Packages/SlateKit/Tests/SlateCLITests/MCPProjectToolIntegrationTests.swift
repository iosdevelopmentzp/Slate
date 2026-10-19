import Foundation
import MCP
import SlateData
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateCLI

@Suite(.serialized, .tags(.integration)) struct MCPProjectToolIntegrationTests {
    private let vault: TemporaryDirectory
    private let support: TemporaryDirectory
    private let code: TemporaryDirectory
    private let keyValues = SpyKeyValueStore()
    private let ports: Ports
    private let useCases: UseCases
    private let runner: MCPToolRunner
    private let shell = ShellRunner(recorder: NoopRecorder())

    init() throws {
        vault = try TemporaryDirectory()
        support = try TemporaryDirectory()
        code = try TemporaryDirectory()
        try FileManager.default.createDirectory(at: vault.url.appendingPathComponent("Notes"), withIntermediateDirectories: true)
        HistorySettings(isEnabled: false).save(to: keyValues)
        ports = try Ports.live(root: vault.url, support: support.url, keyValues: keyValues, recorder: NoopRecorder())
        useCases = UseCases(ports: ports)
        runner = MCPToolRunner(root: vault.url, ports: ports, useCases: useCases) { _ in }
    }

    private var repository: URL {
        code.url.appendingPathComponent("myapp", isDirectory: true)
    }

    private func makeRepository(branch: String = "feature/ABC-123-fix-login") async throws {
        try FileManager.default.createDirectory(at: repository, withIntermediateDirectories: true)
        let identity = ["-c", "user.name=Test", "-c", "user.email=test@example.com"]
        for arguments in [["init", "-q", "-b", branch], ["remote", "add", "origin", "git@gitlab.example.com:group/myapp.git"], identity + ["commit", "-q", "--allow-empty", "-m", "start"]] {
            let result = try await shell.run("git", ["-C", repository.path] + arguments, cwd: nil)
            #expect(result.exitCode == 0, "\(result.stderr)")
        }
    }

    private func call(_ tool: String, _ arguments: [String: Value] = [:]) async -> (text: String, isError: Bool) {
        let result = await runner.call(tool, arguments: arguments)
        let text = result.content.compactMap { content -> String? in
            guard case .text(let text, _, _) = content else { return nil }
            return text
        }.joined()
        return (text, result.isError ?? false)
    }

    private func object(_ text: String) throws -> [String: Any] {
        try #require(try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any])
    }

    private func file(_ path: String) throws -> String {
        try String(contentsOf: vault.url.appendingPathComponent(path), encoding: .utf8)
    }

    @Test func contextFindsTheProjectOfTheRepositoryAndItsCurrentTask() async throws {
        try await makeRepository()
        _ = try await useCases.createProject.execute(name: "MyApp", repositories: [repository.path])
        let started = await call("start_task", ["title": "ABC-123 Fix login", "path": .string(repository.path)])
        #expect(started.isError == false, "\(started.text)")

        let answer = await call("project_context", ["path": .string(repository.path)])

        #expect(answer.isError == false, "\(answer.text)")
        let context = try object(answer.text)
        #expect(context["project"] as? String == "MyApp")
        let tasks = try #require(context["tasks"] as? [[String: Any]])
        #expect(tasks.map { $0["title"] as? String } == ["ABC-123 Fix login"])
        let current = try #require(context["currentTask"] as? [String: Any])
        #expect(current["status"] as? String == "active")
        #expect((context["repository"] as? [String: Any])?["branch"] as? String == "feature/ABC-123-fix-login")
    }

    @Test func aWorktreeAndAFreshCloneFindTheSameProject() async throws {
        try await makeRepository()
        _ = try await useCases.createProject.execute(name: "MyApp", repositories: [repository.path])
        let worktree = code.url.appendingPathComponent("myapp-wt", isDirectory: true)
        let added = try await shell.run("git", ["-C", repository.path, "worktree", "add", "-q", "-b", "feature/ABC-9-other", worktree.path], cwd: nil)
        #expect(added.exitCode == 0, "\(added.stderr)")

        let fromWorktree = try await useCases.findProject.execute(directory: worktree)
        _ = try await useCases.linkRepository.execute(SpaceName(rawValue: "MyApp"), directory: repository)
        var spaces = try await ports.config.spaces()
        spaces.spaces = spaces.spaces.map { space in
            var copy = space
            copy.project?.repositories = []
            return copy
        }
        try await ports.config.saveSpaces(spaces)
        let byRemote = try await useCases.findProject.execute(directory: worktree)

        #expect(fromWorktree?.space.folder.rawValue == "MyApp")
        #expect(fromWorktree?.repository?.branch == "feature/ABC-9-other")
        #expect(byRemote?.space.folder.rawValue == "MyApp")
    }

    @Test func logStatusAndFilesWorkOnATaskByItsTicket() async throws {
        _ = try await useCases.createProject.execute(name: "MyApp")
        let started = try object(await call("start_task", ["title": "Fix login", "ticket": "ABC-7", "project": "MyApp"]).text)
        let path = try #require(started["path"] as? String)
        let folder = try #require(started["folder"] as? String)
        let source = try code.write("boom", to: "crash.log")

        let logged = await call("log_progress", ["task": "ABC-7", "text": "Found the leak. Next: write the fix."])
        let status = await call("set_task_status", ["task": .string(folder), "status": "review"])
        let added = await call("add_file", ["folder": .string(folder), "path": .string(source.path)])
        let pasted = await call("add_file", ["folder": .string(folder), "base64": .string(Data("{}".utf8).base64EncodedString()), "name": "state.json"])
        let listed = await call("list_files", ["folder": .string(folder)])

        #expect(logged.isError == false, "\(logged.text)")
        #expect((try object(logged.text)["entry"] as? String)?.hasSuffix("** Found the leak. Next: write the fix.") == true)
        #expect(status.text == "ABC-7 Fix login is review now.")
        #expect(added.isError == false, "\(added.text)")
        #expect(pasted.isError == false, "\(pasted.text)")
        let text = try file(path)
        #expect(text.contains("status: review"))
        #expect(text.contains("## Log\n\n- **"))
        #expect(text.contains("** Found the leak. Next: write the fix."))
        let files = try #require(try JSONSerialization.jsonObject(with: Data(listed.text.utf8)) as? [[String: Any]])
        #expect(files.map { $0["name"] as? String } == ["crash.log", "state.json"])
    }

    @Test func anUnlinkedDirectoryNamesTheProjectsAndHowToLinkOne() async throws {
        _ = try await useCases.createProject.execute(name: "MyApp")

        let answer = await call("project_context", ["path": .string(code.url.path)])

        #expect(answer.isError)
        #expect(answer.text.contains("Projects: MyApp."))
        #expect(answer.text.contains("Link Repository"))
    }

    @Test func instructionsNameTheProjectOfTheWorkingDirectory() async throws {
        try await makeRepository()
        _ = try await useCases.createProject.execute(name: "MyApp", repositories: [repository.path])
        let match = try await useCases.findProject.execute(directory: repository)

        let text = MCPServerFactory.instructions(for: match, root: vault.url)

        #expect(text.contains("belongs to the Slate project MyApp"))
        #expect(text.contains("log_progress"))
        #expect(MCPServerFactory.instructions(for: nil, root: vault.url).contains("call project_context"))
    }
}
