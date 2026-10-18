import Foundation
import SlateDomain

struct MockExporter: NoteExporting {
    func html(title: String, body: String) -> String {
        "<h1>\(title)</h1><pre>\(body)</pre>"
    }

    func pdf(title: String, body: String) async throws -> Data {
        Data()
    }

    func saveToDownloads(_ data: Data, fileName: String) async throws -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
    }

    func temporaryFile(_ data: Data, fileName: String) async throws -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
    }

    func copyToDownloads(_ source: URL) async throws -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(source.lastPathComponent)
    }
}
