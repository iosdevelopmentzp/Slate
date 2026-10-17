import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct AgentGuideWriterTests {
    private let ports: Ports
    private let spies: PortSpies
    private let claude = VaultPath(rawValue: "CLAUDE.md")
    private let agents = VaultPath(rawValue: "AGENTS.md")

    init() {
        (ports, spies) = Ports.spies()
    }

    private func text(_ path: VaultPath) async throws -> String {
        String(decoding: try await spies.files.read(path).data, as: UTF8.self)
    }

    @Test func aFreshFolderGetsBothFilesWithTheBlock() async throws {
        let written = try await AgentGuideWriter(files: ports.files).execute()

        #expect(written == [claude, agents])
        #expect(try await text(claude) == AgentGuide.block)
        #expect(try await text(agents) == AgentGuide.block)
        #expect(AgentGuide.block.hasPrefix("<!-- slate:begin -->\n# Slate notes folder"))
        #expect(AgentGuide.block.hasSuffix("<!-- slate:end -->\n"))
    }

    @Test func userTextAroundTheMarkersIsKept() async throws {
        spies.files.seed(claude, "# My rules\n\nAlways answer in short.\n\n<!-- slate:begin -->\nold text\n<!-- slate:end -->\n\n## After\n")

        _ = try await AgentGuideWriter(files: ports.files).execute()

        #expect(try await text(claude) == "# My rules\n\nAlways answer in short.\n\n" + AgentGuide.block + "\n## After\n")
    }

    @Test func aFileWithoutMarkersGetsTheBlockAppended() async throws {
        spies.files.seed(claude, "# My rules")

        _ = try await AgentGuideWriter(files: ports.files).execute()

        #expect(try await text(claude) == "# My rules\n\n" + AgentGuide.block)
    }

    @Test func anUpToDateBlockIsNotWrittenAgain() async throws {
        spies.files.seed(claude, "Mine\n\n" + AgentGuide.block)
        spies.files.seed(agents, AgentGuide.block)

        let written = try await AgentGuideWriter(files: ports.files).execute()

        #expect(written.isEmpty)
        #expect(spies.files.calls.contains { if case .write = $0 { true } else { false } } == false)
    }

    @Test func aNewVersionOfTheBlockReplacesTheOldOne() {
        let old = "Top\n<!-- slate:begin -->\nversion 1\n<!-- slate:end -->\nBottom\n"
        let block = "<!-- slate:begin -->\nversion 2\n<!-- slate:end -->\n"

        #expect(AgentGuideWriter.merged(old, block: block) == "Top\n" + block + "Bottom\n")
        #expect(AgentGuideWriter.merged("", block: block) == block)
        #expect(AgentGuideWriter.merged("Top\n", block: block) == "Top\n\n" + block)
    }

    @Test func theBlockNamesTheToolsAndTheRules() {
        for tool in ["list_folders", "list_notes", "search_notes", "read_note", "create_note", "append_to_note", "update_note", "move_note", "trash_note", "attach_image", "open_in_slate"] {
            #expect(AgentGuide.block.contains("`\(tool)`"))
        }
        #expect(AgentGuide.block.contains(AgentGuide.registration))
        #expect(AgentGuide.block.contains("Never write into `.slate/` or `.trash/`"))
    }
}
