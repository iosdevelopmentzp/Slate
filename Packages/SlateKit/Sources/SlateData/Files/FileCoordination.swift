import Foundation
import SlateDomain

enum FileCoordination {

    static func reading<T>(_ url: URL, _ body: (URL) throws -> T) throws -> T {
        var coordinationError: NSError?
        var result: Result<T, any Error>?
        NSFileCoordinator(filePresenter: nil).coordinate(readingItemAt: url, options: [], error: &coordinationError) { actual in
            result = Result { try body(actual) }
        }
        return try unwrap(result, coordinationError)
    }

    static func writing<T>(_ url: URL, _ body: (URL) throws -> T) throws -> T {
        var coordinationError: NSError?
        var result: Result<T, any Error>?
        NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: url, options: .forReplacing, error: &coordinationError) { actual in
            result = Result { try body(actual) }
        }
        return try unwrap(result, coordinationError)
    }

    static func moving(from source: URL, to target: URL) throws {
        var coordinationError: NSError?
        var result: Result<Void, any Error>?
        let coordinator = NSFileCoordinator(filePresenter: nil)
        coordinator.coordinate(writingItemAt: source, options: .forMoving, writingItemAt: target, options: .forReplacing, error: &coordinationError) { from, to in
            result = Result {
                try FileManager.default.moveItem(at: from, to: to)
                coordinator.item(at: from, didMoveTo: to)
            }
        }
        try unwrap(result, coordinationError)
    }

    static func replace(_ url: URL, with data: Data) throws {
        let folder = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let temporary = folder.appendingPathComponent(".\(url.lastPathComponent).slate-tmp")
        do {
            try data.write(to: temporary)
            if FileManager.default.fileExists(atPath: url.path) {
                _ = try FileManager.default.replaceItemAt(url, withItemAt: temporary)
            } else {
                try FileManager.default.moveItem(at: temporary, to: url)
            }
        } catch {
            try? FileManager.default.removeItem(at: temporary)
            throw error
        }
    }

    static func writeCoordinated(_ url: URL, data: Data) throws {
        try writing(url) { actual in
            try replace(actual, with: data)
        }
    }

    static func readCoordinated(_ url: URL) throws -> Data {
        try reading(url) { actual in
            try Data(contentsOf: actual)
        }
    }

    private static func unwrap<T>(_ result: Result<T, any Error>?, _ coordinationError: NSError?) throws -> T {
        if let coordinationError { throw coordinationError }
        guard let result else { throw CocoaError(.fileReadUnknown) }
        return try result.get()
    }
}
