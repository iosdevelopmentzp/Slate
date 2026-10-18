import Foundation
import SlateDomain

enum GitChangesParser {
    static let separator = "\u{1E}"
    static let format = "\(separator)\(GitLogParser.format)"

    static func changes(from output: String) -> [SnapshotChange] {
        output.components(separatedBy: separator).compactMap { block -> SnapshotChange? in
            let lines = block.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
            guard let head = lines.first, let snapshot = GitLogParser.snapshots(from: head).first else { return nil }
            let files = lines.dropFirst().flatMap(Self.files)
            return SnapshotChange(snapshot: snapshot, files: files)
        }
    }

    private static func files(from line: String) -> [ChangedFile] {
        let parts = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 2, let status = parts.first?.first else { return [] }
        switch status {
        case "A", "C": return [ChangedFile(path: VaultPath(rawValue: parts[parts.count - 1]), kind: .added)]
        case "D": return [ChangedFile(path: VaultPath(rawValue: parts[1]), kind: .removed)]
        case "R" where parts.count >= 3:
            return [ChangedFile(path: VaultPath(rawValue: parts[1]), kind: .removed), ChangedFile(path: VaultPath(rawValue: parts[2]), kind: .added)]
        default: return [ChangedFile(path: VaultPath(rawValue: parts[parts.count - 1]), kind: .changed)]
        }
    }
}
