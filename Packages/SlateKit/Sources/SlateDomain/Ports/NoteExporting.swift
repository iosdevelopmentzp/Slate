import Foundation

package protocol NoteExporting: Sendable {
    func html(title: String, body: String) -> String
    func pdf(title: String, body: String) async throws -> Data
    func saveToDownloads(_ data: Data, fileName: String) async throws -> URL
}
