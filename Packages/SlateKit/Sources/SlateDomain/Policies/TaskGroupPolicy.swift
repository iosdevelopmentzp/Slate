import Foundation

package enum TaskGroupPolicy {
    package enum Group: String, CaseIterable, Hashable, Sendable {
        case active
        case todo
        case done
    }

    package static func group(for status: NoteStatus?) -> Group {
        switch status {
        case .active, .review: .active
        case .done, .dropped: .done
        case .todo, nil: .todo
        }
    }

    package static func grouped(_ notes: [NoteSummary]) -> [(group: Group, notes: [NoteSummary])] {
        Group.allCases.compactMap { group in
            let matching = notes.filter { self.group(for: $0.status) == group }
            return matching.isEmpty ? nil : (group, matching)
        }
    }
}
