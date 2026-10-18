import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct ImportFolderUseCaseTests {
    @Test func aHiddenFolderIsNamedAfterItsRepository() {
        #expect(ImportFolderUseCase.name(for: URL(fileURLWithPath: "/dev/myapp/.slate")) == "myapp")
        #expect(ImportFolderUseCase.name(for: URL(fileURLWithPath: "/dev/docs/")) == "docs")
    }

    @Test func importMakesAProjectCopiesTheFolderAndLinksTheRepository() async throws {
        let (ports, spies) = Ports.spies()
        spies.files.importResult = FolderImport(notes: 3, files: 2, repository: "/dev/myapp")

        let imported = try await UseCases(ports: ports).importFolder.execute(URL(fileURLWithPath: "/dev/myapp/.slate"))

        #expect(imported.space == SpaceName(rawValue: "myapp"))
        #expect(imported.report.notes == 3)
        #expect(spies.files.calls.contains(.importFolder(".slate", into: FolderPath(rawValue: "myapp"))))
        let project = try #require(spies.config.config.space(imported.space)?.project)
        #expect(project.repositories == ["/dev/myapp"])
    }

    @Test func aTakenNameGetsANumber() async throws {
        let (ports, _) = Ports.spies()

        let imported = try await UseCases(ports: ports).importFolder.execute(URL(fileURLWithPath: "/dev/Notes"))

        #expect(imported.space == SpaceName(rawValue: "Notes 2"))
    }
}
