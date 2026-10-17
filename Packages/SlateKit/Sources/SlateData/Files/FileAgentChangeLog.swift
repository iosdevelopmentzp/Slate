import Foundation
import SlateDomain

actor FileAgentChangeLog: AgentChangeLog {
    static let fileName = "agent-changes.jsonl"
    static let keep = 200

    let url: URL

    init(url: URL) {
        self.url = url
    }

    func record(_ change: AgentChange) throws {
        var lines = try readLines()
        lines.append(String(decoding: try JSONEncoder().encode(change), as: UTF8.self))
        let kept = lines.suffix(Self.keep)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data((kept.joined(separator: "\n") + "\n").utf8).write(to: url, options: .atomic)
    }

    func changes(after date: Date) throws -> [AgentChange] {
        let decoder = JSONDecoder()
        return try readLines()
            .compactMap { try? decoder.decode(AgentChange.self, from: Data($0.utf8)) }
            .filter { $0.date > date }
    }

    private func readLines() throws -> [String] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return String(decoding: try Data(contentsOf: url), as: UTF8.self)
            .split(separator: "\n")
            .map(String.init)
    }
}
