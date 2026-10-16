import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateData

@Suite struct FileVaultConfigRepositoryTests {
    private let folder: TemporaryDirectory
    private let repository: FileVaultConfigRepository

    init() throws {
        folder = try TemporaryDirectory()
        repository = FileVaultConfigRepository(root: folder.url)
    }

    private func makeFolders(_ names: [String]) throws {
        for name in names {
            try FileManager.default.createDirectory(at: folder.url.appendingPathComponent(name), withIntermediateDirectories: true)
        }
    }

    @Test func withoutAFileTheDefaultOrderAppliesToExistingFolders() async throws {
        try makeFolders(["Work", "Notes", "Ideas", "_attachments", ".slate"])

        let config = try await repository.spaces()

        #expect(config.spaces.map(\.folder.rawValue) == ["Notes", "Ideas", "Work"])
        #expect(config.spaces.first?.icon == "folder.fill")
        #expect(config.spaces.last?.icon == "folder")
        #expect(config.captureSpace == SpaceName(rawValue: "Notes"))
    }

    @Test func savedOrderAndIconsAreReadBackAndUnknownKeysSurvive() async throws {
        try makeFolders(["Inbox", "Tasks"])
        _ = try folder.write(#"{"version": 1, "theme": "x", "spaces": [{"folder": "Tasks", "icon": "star", "color": "red"}, {"folder": "Inbox"}]}"#, to: ".slate/spaces.json")

        var config = try await repository.spaces()
        #expect(config.spaces.map(\.folder.rawValue) == ["Tasks", "Inbox"])
        #expect(config.spaces.first?.icon == "star")

        config.spaces[0].icon = "bolt"
        try await repository.saveSpaces(config)

        let text = try String(contentsOf: folder.url.appendingPathComponent(".slate/spaces.json"), encoding: .utf8)
        #expect(text.contains(#""theme" : "x""#))
        #expect(text.contains(#""color" : "red""#))
        #expect(try await repository.spaces().spaces.first?.icon == "bolt")
    }

    @Test func folderMissingOnDiskIsDropped() async throws {
        try makeFolders(["Inbox"])
        _ = try folder.write(#"{"version": 1, "spaces": [{"folder": "Gone"}, {"folder": "Inbox"}]}"#, to: ".slate/spaces.json")

        #expect(try await repository.spaces().spaces.map(\.folder.rawValue) == ["Inbox"])
    }

    @Test func userTypeFilesExtendTheBuiltIns() async throws {
        _ = try folder.write(#"{"version": 1, "type": "bug", "title": "Bug", "icon": "ant", "defaultSpace": "Tasks", "fields": ["ticket"]}"#, to: ".slate/types/bug.json")
        _ = try folder.write(#"{"version": 1, "type": "task", "title": "Job", "icon": "briefcase"}"#, to: ".slate/types/task.json")

        let types = try await repository.types()

        #expect(types.map(\.name) == ["note", "task", "daily", "snippet", "meeting", "bug"])
        #expect(types.first { $0.name == "task" }?.title == "Job")
        #expect(types.last?.defaultSpace == SpaceName(rawValue: "Tasks"))
    }

    @Test func ensureDefaultsWritesOnlyTheFolderList() async throws {
        try makeFolders(["Notes"])

        try await repository.ensureDefaults()

        #expect(FileManager.default.fileExists(atPath: folder.path(".slate/spaces.json")))
        let written = try FileManager.default.contentsOfDirectory(atPath: folder.path(".slate"))
        #expect(written == ["spaces.json"])
    }

    @Test func withoutFilesViewsAndActionsAreTheBuiltInOnes() async throws {
        #expect(try await repository.views().map(\.id) == ["open-todos", "active-tasks", "this-week", "untagged", "conflicts"])
        #expect(try await repository.actions().isEmpty)
    }

    @Test func linkPatternsRoundTripAndKeepUnknownKeys() async throws {
        try makeFolders(["Inbox"])
        _ = try folder.write(#"{"version": 1, "patterns": [{"id": "jira", "regex": "x", "url": "u/$1", "label": "$1", "color": "blue"}]}"#, to: ".slate/links.json")

        try await repository.saveLinkPatterns([LinkPattern(id: "jira", regex: "y", url: "v/$1", label: "$1")])

        #expect(try await repository.linkPatterns() == [LinkPattern(id: "jira", regex: "y", url: "v/$1", label: "$1")])
        let text = try String(contentsOf: folder.url.appendingPathComponent(".slate/links.json"), encoding: .utf8)
        #expect(text.contains(#""color" : "blue""#))
    }
}
