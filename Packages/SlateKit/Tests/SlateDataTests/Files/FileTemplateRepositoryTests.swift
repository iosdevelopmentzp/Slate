import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateData

@Suite struct FileTemplateRepositoryTests {
    @Test func ensureDefaultsWritesMissingTemplatesOnly() async throws {
        let folder = try TemporaryDirectory()
        _ = try folder.write("mine", to: "_templates/task.md")
        let repository = FileTemplateRepository(root: folder.url)

        try await repository.ensureDefaults()

        #expect(try await repository.body(for: "task") == "mine")
        #expect(try await repository.body(for: "meeting") == BuiltInTemplates.bodies["meeting"])
        #expect(FileManager.default.fileExists(atPath: folder.path("_templates/note.md")))
    }

    @Test func missingTemplateFallsBackToTheBuiltInOrEmpty() async throws {
        let repository = FileTemplateRepository(root: try TemporaryDirectory().url)

        #expect(try await repository.body(for: "daily") == BuiltInTemplates.bodies["daily"])
        #expect(try await repository.body(for: "custom") == "")
    }
}
