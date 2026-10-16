import Foundation

enum NoteStems {

    static func stems(inFolder folder: String, files: any VaultFileStore, excluding current: VaultPath? = nil) async throws -> [String] {
        let suffix = ".\(VaultPath.noteExtension)"
        return try await files.fileNames(inFolder: folder)
            .filter { $0.hasSuffix(suffix) && $0 != current?.fileName }
            .map { String($0.dropLast(suffix.count)) }
    }
}
