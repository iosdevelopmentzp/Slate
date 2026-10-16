import Foundation

package protocol AttachmentStore: Sendable {
    func fileNames() async throws -> [String]
    func write(_ data: Data, named name: String) async throws
    func copy(_ source: URL, named name: String) async throws
    func size(of name: String) async -> Int?
    func externalSize(_ url: URL) async -> Int?
    func url(for name: String) -> URL
}
