import Foundation

package struct ImportFolderUseCase: Sendable {
    let files: any VaultFileStore
    let config: any VaultConfigRepository
    let createProject: CreateProjectUseCase
    let setProject: SetProjectUseCase
    let reindex: ReindexVaultUseCase

    package func execute(_ source: URL) async throws -> ImportedProject {
        let taken = try await config.spaces().spaces.map(\.folder.rawValue)
        let wanted = SpaceNamePolicy.validated(Self.name(for: source))?.rawValue ?? "Imported"
        let space = try await createProject.execute(name: StemPolicy.unique(wanted, among: taken))
        let report = try await files.importFolder(source, into: FolderPath(space: space))
        if let repository = report.repository, var project = try await config.spaces().space(space)?.project {
            project.repositories = [repository]
            try await setProject.execute(space, project: project)
        }
        _ = try await reindex.execute(.all)
        return ImportedProject(space: space, report: report)
    }

    static func name(for source: URL) -> String {
        let last = source.standardizedFileURL.lastPathComponent
        guard last.hasPrefix(".") else { return last }
        return source.standardizedFileURL.deletingLastPathComponent().lastPathComponent
    }
}
