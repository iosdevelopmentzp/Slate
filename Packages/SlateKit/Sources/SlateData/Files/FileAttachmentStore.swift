import Foundation
import SlateDomain

struct FileAttachmentStore: AttachmentStore {
    let root: URL

    private var folder: URL {
        root.appendingPathComponent(AttachmentPolicy.folder, isDirectory: true)
    }

    func fileNames() async throws -> [String] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        return names.filter { $0.hasPrefix(".") == false }
    }

    func write(_ data: Data, named name: String) async throws {
        let url = try target(name)
        try FileCoordination.writing(url) { actual in
            guard FileManager.default.fileExists(atPath: actual.path) == false else { throw VaultError.alreadyExists(name) }
            try FileCoordination.replace(actual, with: data)
        }
    }

    func copy(_ source: URL, named name: String) async throws {
        let url = try target(name)
        let data = try FileCoordination.readCoordinated(source)
        try FileCoordination.writing(url) { actual in
            guard FileManager.default.fileExists(atPath: actual.path) == false else { throw VaultError.alreadyExists(name) }
            try FileCoordination.replace(actual, with: data)
        }
    }

    func size(of name: String) async -> Int? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url(for: name).path)
        return (attributes?[.size] as? NSNumber)?.intValue
    }

    func externalSize(_ url: URL) async -> Int? {
        (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize
    }

    func url(for name: String) -> URL {
        folder.appendingPathComponent(name, isDirectory: false)
    }

    private func target(_ name: String) throws -> URL {
        guard name.isEmpty == false, name.contains("/") == false, name.hasPrefix(".") == false else { throw VaultError.invalidName(name) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return url(for: name)
    }
}
