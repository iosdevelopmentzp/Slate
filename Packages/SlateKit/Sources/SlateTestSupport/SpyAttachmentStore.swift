import Foundation
import SlateDomain

package final class SpyAttachmentStore: AttachmentStore, @unchecked Sendable {
    package enum Call: Hashable {
        case write(String)
        case copy(URL, String)
    }

    package static let folder = URL(fileURLWithPath: "/vault/_attachments", isDirectory: true)

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _files: [String: Data] = [:]
    private var _externalSizes: [URL: Int] = [:]

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var files: [String: Data] {
        lock.withLock { _files }
    }

    package func seed(_ name: String, _ data: Data = Data([1])) {
        lock.withLock { _files[name] = data }
    }

    package func fileNames() async throws -> [String] {
        lock.withLock { Array(_files.keys).sorted() }
    }

    package func write(_ data: Data, named name: String) async throws {
        try lock.withLock {
            guard _files[name] == nil else { throw VaultError.alreadyExists(name) }
            _calls.append(.write(name))
            _files[name] = data
        }
    }

    package func copy(_ source: URL, named name: String) async throws {
        try lock.withLock {
            guard _files[name] == nil else { throw VaultError.alreadyExists(name) }
            _calls.append(.copy(source, name))
            _files[name] = Data([1])
        }
    }

    package func size(of name: String) async -> Int? {
        lock.withLock { _files[name]?.count }
    }

    package func externalSize(_ url: URL) async -> Int? {
        lock.withLock { _externalSizes[url] }
    }

    package func setExternalSize(_ size: Int, for url: URL) {
        lock.withLock { _externalSizes[url] = size }
    }

    package func url(for name: String) -> URL {
        Self.folder.appendingPathComponent(name)
    }
}
