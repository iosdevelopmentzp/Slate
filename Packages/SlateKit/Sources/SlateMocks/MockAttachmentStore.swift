import Foundation
import SlateDomain

actor MockAttachmentStore: AttachmentStore {
    private var files: [String: Data] = [:]

    func fileNames() -> [String] {
        Array(files.keys)
    }

    func write(_ data: Data, named name: String) {
        files[name] = data
    }

    func copy(_ source: URL, named name: String) {
        files[name] = Data()
    }

    func size(of name: String) -> Int? {
        files[name]?.count
    }

    func externalSize(_ url: URL) -> Int? {
        nil
    }

    nonisolated func url(for name: String) -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
    }
}
