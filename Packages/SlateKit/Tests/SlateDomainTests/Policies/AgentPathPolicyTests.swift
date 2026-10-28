import Foundation
import Testing
@testable import SlateDomain

@Suite struct AgentPathPolicyTests {
    private let root = URL(fileURLWithPath: "/vault", isDirectory: true)

    @Test func aFilePathIsRelativeOrInsideTheNotesFolder() throws {
        #expect(try AgentPathPolicy.filePath(from: "Work/App.swift", root: root) == VaultPath(rawValue: "Work/App.swift"))
        #expect(try AgentPathPolicy.filePath(from: "/vault/Work/Logs/crash.log", root: root) == VaultPath(rawValue: "Work/Logs/crash.log"))
    }

    @Test func aFilePathOutsideTheFoldersIsRefused() {
        #expect(throws: AgentError.outsideFiles("/etc/hosts")) { try AgentPathPolicy.filePath(from: "/etc/hosts", root: root) }
        #expect(throws: AgentError.outsideFiles("Work/../x.txt")) { try AgentPathPolicy.filePath(from: "Work/../x.txt", root: root) }
        #expect(throws: AgentError.outsideFiles("root.txt")) { try AgentPathPolicy.filePath(from: "root.txt", root: root) }
        #expect(throws: AgentError.outsideFiles(".slate/spaces.json")) { try AgentPathPolicy.filePath(from: ".slate/spaces.json", root: root) }
    }

    @Test func aNoteIsNotAFile() {
        #expect(throws: AgentError.isNote("Work/Plan.md")) { try AgentPathPolicy.filePath(from: "Work/Plan.md", root: root) }
    }
}
