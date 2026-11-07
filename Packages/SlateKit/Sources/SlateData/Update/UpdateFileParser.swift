import Foundation
import SlateDomain

enum UpdateFileParser {
    private struct InstalledDTO: Decodable {
        let commit: String
        let branch: String?
        let source: String
    }

    private struct StatusDTO: Decodable {
        let phase: String
        let startedAt: String?
        let commit: String?
        let message: String?
    }

    static func installed(_ data: Data) -> InstalledBuild? {
        guard let dto = try? JSONDecoder().decode(InstalledDTO.self, from: data), dto.commit.isEmpty == false, dto.source.isEmpty == false else { return nil }
        return InstalledBuild(commit: dto.commit, branch: dto.branch.flatMap { $0.isEmpty ? nil : $0 } ?? "main", source: dto.source)
    }

    static func status(_ data: Data) -> UpdateStatus? {
        guard let dto = try? JSONDecoder().decode(StatusDTO.self, from: data), let phase = UpdateStatus.Phase(rawValue: dto.phase) else { return nil }
        let started = dto.startedAt.flatMap { try? Date($0, strategy: .iso8601) } ?? .distantPast
        return UpdateStatus(phase: phase, startedAt: started, commit: dto.commit.flatMap { $0.isEmpty ? nil : $0 }, message: dto.message.flatMap { $0.isEmpty ? nil : $0 })
    }

    static func commits(_ output: String) -> [UpdateCommit] {
        output.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "\u{1F}", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return nil }
            return UpdateCommit(hash: parts[0], subject: parts[1])
        }
    }
}
