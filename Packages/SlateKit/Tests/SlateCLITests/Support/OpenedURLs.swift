import Foundation

final class OpenedURLs: @unchecked Sendable {
    private let lock = NSLock()
    private var _urls: [URL] = []

    var urls: [URL] {
        lock.withLock { _urls }
    }

    func append(_ url: URL) {
        lock.withLock { _urls.append(url) }
    }
}
