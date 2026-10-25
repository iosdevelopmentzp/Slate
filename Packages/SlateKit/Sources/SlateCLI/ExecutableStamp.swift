import Foundation

struct ExecutableStamp: Sendable, Equatable {
    let path: String
    let fileNumber: Int
    let modified: Date

    init?(path: String) {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path),
              let fileNumber = (attributes[.systemFileNumber] as? NSNumber)?.intValue,
              let modified = attributes[.modificationDate] as? Date
        else { return nil }
        self.path = path
        self.fileNumber = fileNumber
        self.modified = modified
    }

    static func current() -> ExecutableStamp? {
        Bundle.main.executablePath.flatMap(ExecutableStamp.init(path:))
    }

    var isReplaced: Bool {
        ExecutableStamp(path: path).map { $0 != self } ?? false
    }
}
