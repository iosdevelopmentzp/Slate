import Foundation
import MCP

enum MCPServerFactory {
    static let instructions = "Slate notes: Markdown files in folders. Read CLAUDE.md in the notes folder for the rules. Find a note with list_notes or search_notes, read it with read_note, change it with append_to_note or update_note."

    static func server(runner: MCPToolRunner) async -> Server {
        let server = Server(
            name: "slate",
            version: VersionCommand.version,
            instructions: instructions,
            capabilities: Server.Capabilities(resources: .init(subscribe: false, listChanged: false), tools: .init(listChanged: false))
        )
        await server.withMethodHandler(ListTools.self) { _ in
            ListTools.Result(tools: MCPToolCatalog.tools)
        }
        await server.withMethodHandler(CallTool.self) { parameters in
            await runner.call(parameters.name, arguments: parameters.arguments)
        }
        await server.withMethodHandler(ListResources.self) { _ in
            ListResources.Result(resources: try await runner.resources())
        }
        await server.withMethodHandler(ListResourceTemplates.self) { _ in
            ListResourceTemplates.Result(templates: [
                Resource.Template(uriTemplate: MCPToolRunner.notePrefix + "{id}", name: "note", description: "The text of a Slate note, by its id.", mimeType: "text/markdown"),
            ])
        }
        await server.withMethodHandler(ReadResource.self) { parameters in
            ReadResource.Result(contents: [.text(try await runner.readResource(parameters.uri), uri: parameters.uri, mimeType: "text/markdown")])
        }
        return server
    }
}
