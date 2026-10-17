import ArgumentParser
import Foundation
import MCP

struct MCPCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "mcp", abstract: "Run the MCP server for AI agents over standard input and output.")

    @OptionGroup var options: VaultOptions

    func run() async throws {
        let container = try CLIContainer(options: options)
        let runner = MCPToolRunner(root: container.root, ports: container.ports, useCases: container.useCases) { url in
            _ = try await CLIShell.open(url)
        }
        let server = await MCPServerFactory.server(runner: runner)
        try await server.start(transport: StdioTransport())
        await server.waitUntilCompleted()
    }
}
