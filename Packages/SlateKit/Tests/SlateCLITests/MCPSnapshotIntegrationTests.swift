import Foundation
import MCP
import SlateData
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateCLI

@Suite(.serialized, .tags(.integration)) struct MCPSnapshotIntegrationTests {
    @Test func everyAgentWriteLeavesAVersionWithTheToolAndTheTitle() async throws {
        let vault = try TemporaryDirectory()
        let support = try TemporaryDirectory()
        try FileManager.default.createDirectory(at: vault.url.appendingPathComponent("Notes"), withIntermediateDirectories: true)
        let ports = try Ports.live(root: vault.url, support: support.url, keyValues: SpyKeyValueStore(), recorder: NoopRecorder())
        let runner = MCPToolRunner(root: vault.url, ports: ports, useCases: UseCases(ports: ports)) { _ in }
        _ = try vault.write("---\ntitle: Groceries\n---\nMilk\n", to: "Notes/Groceries.md")
        _ = try await UseCases(ports: ports).reindex.execute(.all)
        let id = try #require(try await ports.index.summaries(space: nil).first?.id.rawValue)

        let result = await runner.call("append_to_note", arguments: ["id": .string(id), "text": "Eggs"])

        #expect(result.isError != true)
        let versions = try await ports.history.history(of: VaultPath(rawValue: "Notes/Groceries.md"))
        #expect(versions.map(\.message) == ["agent: append_to_note Groceries", "snapshot: 1 file"])
        let older = try await ports.history.contents(of: VaultPath(rawValue: "Notes/Groceries.md"), at: versions[1].hash)
        #expect(String(decoding: older, as: UTF8.self) == "---\ntitle: Groceries\n---\nMilk\n")
    }
}
