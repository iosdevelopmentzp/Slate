import Foundation
import SlateDomain

enum GitLogParser {
    static let format = "%H%x09%ct%x09%s"

    static func snapshots(from output: String) -> [Snapshot] {
        output.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false).map(String.init)
            guard parts.count >= 2, parts[0].count >= 7, let seconds = TimeInterval(parts[1]) else { return nil }
            return Snapshot(hash: parts[0], date: Date(timeIntervalSince1970: seconds), message: parts.count > 2 ? parts[2] : "")
        }
    }
}
