import Foundation
import SlateDomain

package final class SpyExporter: NoteExporting, @unchecked Sendable {
    private let lock = NSLock()
    private var _saved: [String: Data] = [:]

    package init() {}

    package var saved: [String: Data] {
        lock.withLock { _saved }
    }

    package func html(title: String, body: String) -> String {
        "<h1>\(title)</h1>\(body)"
    }

    package func pdf(title: String, body: String) async throws -> Data {
        Data("%PDF \(title)".utf8)
    }

    package func saveToDownloads(_ data: Data, fileName: String) async throws -> URL {
        lock.withLock { _saved[fileName] = data }
        return URL(fileURLWithPath: "/Downloads").appendingPathComponent(fileName)
    }
}
