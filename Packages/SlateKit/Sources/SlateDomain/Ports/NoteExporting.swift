import Foundation

package protocol NoteExporting: Sendable {
    func html(title: String, body: String, folder: URL?) -> String
    func pdf(title: String, body: String, folder: URL?) async throws -> Data
    func saveToDownloads(_ data: Data, fileName: String) async throws -> URL
    func copyToDownloads(_ source: URL) async throws -> URL
    func temporaryFile(_ data: Data, fileName: String) async throws -> URL
}
