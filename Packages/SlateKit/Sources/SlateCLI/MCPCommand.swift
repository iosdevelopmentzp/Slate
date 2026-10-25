import ArgumentParser
import Foundation
import MCP
import SlateDomain

struct MCPCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "mcp", abstract: "Run the MCP server for AI agents over standard input and output.")

    @OptionGroup var options: VaultOptions

    func run() async throws {
        let container = try CLIContainer(options: options)
        var runner = MCPToolRunner(root: container.root, ports: container.ports, useCases: container.useCases) { url in
            _ = try await CLIShell.open(url)
        }
        runner.executable = .current()
        let match = try? await container.useCases.findProject.execute(directory: runner.workingDirectory)
        let server = await MCPServerFactory.server(runner: runner, instructions: MCPServerFactory.instructions(for: match, root: container.root))
        try await server.start(transport: StdioTransport())
        await server.waitUntilCompleted()
    }
}
