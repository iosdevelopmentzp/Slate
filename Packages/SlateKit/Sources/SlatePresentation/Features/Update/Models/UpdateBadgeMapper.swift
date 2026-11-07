import Foundation
import SlateDomain

enum UpdateBadgeMapper {
    static let shownCommits = 10

    static func title(for state: UpdateStore.State, now: Date) -> String? {
        switch state {
        case .idle:
            nil
        case .available(let commits):
            commits.count == 1 ? "Update available · 1 change" : "Update available · \(commits.count) changes"
        case .running(let phase, let startedAt):
            "\(phaseTitle(phase)) · \(elapsed(from: startedAt, to: now))"
        case .failed:
            "Update failed"
        }
    }

    static func phaseTitle(_ phase: UpdateStatus.Phase) -> String {
        switch phase {
        case .fetching: "Getting changes"
        case .building: "Building"
        case .installing, .done: "Installing"
        case .failed: "Failed"
        }
    }

    static func elapsed(from start: Date, to now: Date) -> String {
        let seconds = max(Int(now.timeIntervalSince(start)), 0)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    static func lines(of commits: [UpdateCommit]) -> [String] {
        let shown = commits.prefix(shownCommits).map(\.subject)
        let rest = commits.count - shown.count
        return rest > 0 ? shown + ["and \(rest) more"] : shown
    }

    static func logTail(_ log: String, lines count: Int = 40) -> String {
        log.split(separator: "\n", omittingEmptySubsequences: false).suffix(count).joined(separator: "\n")
    }
}
