import Foundation
import Testing
@testable import SlateDomain

@Suite struct AgentPermissionsTests {
    private let root = URL(fileURLWithPath: "/Users/me/Notes", isDirectory: true)

    @Test func defaultsAllowCreateInNotesOnly() {
        let permissions = AgentPermissions()

        #expect(permissions.writableFolders == ["Notes"])
        #expect(permissions.allowCreate)
        #expect(permissions.allowTrash == false)
    }

    @Test func aFolderAllowsItsSubFoldersButNotItsNeighbours() {
        let permissions = AgentPermissions(writableFolders: ["Work/"])

        #expect(permissions.canWrite(in: FolderPath(rawValue: "Work")))
        #expect(permissions.canWrite(in: FolderPath(rawValue: "work/Clients")))
        #expect(permissions.canWrite(in: FolderPath(rawValue: "Workshop")) == false)
        #expect(permissions.canWrite(in: FolderPath(rawValue: "Notes")) == false)
    }

    @Test func hiddenAndUnderscoreFoldersAreNeverWritable() {
        let permissions = AgentPermissions(writableFolders: [".slate", "_templates", "Work"])

        #expect(permissions.canWrite(in: FolderPath(rawValue: ".slate")) == false)
        #expect(permissions.canWrite(in: FolderPath(rawValue: "_templates")) == false)
        #expect(permissions.canWrite(in: FolderPath(rawValue: "Work/.trash")) == false)
    }

    @Test func writeOutsideTheListSaysWhichFoldersAreAllowed() {
        let permissions = AgentPermissions(writableFolders: ["AI", "Notes"])

        #expect(throws: AgentError.folderNotAllowed("Work", allowed: ["AI", "Notes"])) {
            try permissions.checkWrite(VaultPath(rawValue: "Work/Plan.md"))
        }
        #expect(AgentError.folderNotAllowed("Work", allowed: ["AI", "Notes"]).localizedDescription.hasPrefix("Agents may not change notes in Work. Allowed: AI, Notes."))
        try? permissions.checkWrite(VaultPath(rawValue: "AI/Plan.md"))
    }

    @Test func createAndTrashFollowTheirFlags() throws {
        let closed = AgentPermissions(allowCreate: false, allowTrash: false)
        let open = AgentPermissions(allowCreate: true, allowTrash: true)
        let notes = FolderPath(rawValue: "Notes")
        let path = VaultPath(rawValue: "Notes/Plan.md")

        #expect(throws: AgentError.createNotAllowed) { try closed.checkCreate(in: notes) }
        #expect(throws: AgentError.trashNotAllowed) { try closed.checkTrash(path) }
        try open.checkCreate(in: notes)
        try open.checkTrash(path)
        #expect(throws: AgentError.self) { try open.checkTrash(VaultPath(rawValue: "Work/Plan.md")) }
    }

    @Test func settingAFolderAddsOrRemovesIt() {
        let permissions = AgentPermissions(writableFolders: ["Notes"])

        #expect(permissions.setting("Work", writable: true).writableFolders == ["Notes", "Work"])
        #expect(permissions.setting("notes", writable: false).writableFolders == [])
    }

    @Test func missingKeysTakeTheDefaults() throws {
        let decoded = try JSONDecoder().decode(AgentPermissions.self, from: Data(#"{"writableFolders":["AI"]}"#.utf8))

        #expect(decoded == AgentPermissions(writableFolders: ["AI"]))
    }

    @Test func notePathsInsideTheFolderAreAccepted() throws {
        #expect(try AgentPathPolicy.notePath(from: "Notes/Plan.md", root: root) == VaultPath(rawValue: "Notes/Plan.md"))
        #expect(try AgentPathPolicy.notePath(from: "/Users/me/Notes/Work/Clients/Call.md", root: root) == VaultPath(rawValue: "Work/Clients/Call.md"))
    }

    @Test(arguments: [
        "../secrets.md", "Notes/../../x.md", "/etc/hosts.md", "/Users/me/NotesOther/a.md", ".slate/agents.json",
        ".trash/Notes/a.md", "_templates/task.md", "_attachments/a.md", "Plan.md", "Notes/Plan.txt", "Notes//Plan.md",
    ])
    func pathEscapesAreRejected(_ raw: String) {
        #expect(throws: AgentError.self) { try AgentPathPolicy.notePath(from: raw, root: root) }
    }

    @Test func foldersAreCheckedTheSameWay() throws {
        #expect(try AgentPathPolicy.folder(from: "/Work/Clients/") == FolderPath(rawValue: "Work/Clients"))
        #expect(throws: AgentError.self) { try AgentPathPolicy.folder(from: "Work/../..") }
        #expect(throws: AgentError.self) { try AgentPathPolicy.folder(from: ".slate") }
        #expect(throws: AgentError.self) { try AgentPathPolicy.folder(from: " ") }
    }
}
