import Foundation

package protocol VaultFileStore: Sendable {
    func enumerate() async throws -> [FileMeta]
    func read(_ path: VaultPath) async throws -> FileContents
    func meta(_ path: VaultPath) async throws -> FileMeta?
    func write(_ path: VaultPath, data: Data, expected: ContentHash?) async throws -> WriteResult
    func create(_ path: VaultPath, data: Data) async throws -> ContentHash
    func move(from: VaultPath, to: VaultPath) async throws
    func fileNames(inFolder folder: String) async throws -> [String]
    func folders() async throws -> [FolderPath]
    func createFolder(_ folder: FolderPath) async throws
    func moveFolder(from: FolderPath, to: FolderPath) async throws
    func removeFolder(_ folder: FolderPath) async throws
}
