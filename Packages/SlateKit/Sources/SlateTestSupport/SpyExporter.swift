import Foundation
import SlateDomain

package final class SpyExporter: NoteExporting, @unchecked Sendable {
    private let lock = NSLock()
    private var _saved: [String: Data] = [:]
    private var _copied: [URL] = []

    package var copyError: (any Error)?

    package init() {}

    package var saved: [String: Data] {
        lock.withLock { _saved }
    }

    package var copied: [URL] {
        lock.withLock { _copied }
    }

    package func html(title: String, body: String, folder: URL?) -> String {
        "<h1>\(title)</h1>\(body)"
    }

    package func pdf(title: String, body: String, folder: URL?) async throws -> Data {
        Data("%PDF \(title)".utf8)
    }

    package func saveToDownloads(_ data: Data, fileName: String) async throws -> URL {
        lock.withLock { _saved[fileName] = data }
        return URL(fileURLWithPath: "/Downloads").appendingPathComponent(fileName)
    }

    package func temporaryFile(_ data: Data, fileName: String) async throws -> URL {
        lock.withLock { _saved["tmp/\(fileName)"] = data }
        return URL(fileURLWithPath: "/tmp").appendingPathComponent(fileName)
    }

    package func copyToDownloads(_ source: URL) async throws -> URL {
        if let copyError { throw copyError }
        lock.withLock { _copied.append(source) }
        return URL(fileURLWithPath: "/Downloads").appendingPathComponent(source.lastPathComponent)
    }
}
