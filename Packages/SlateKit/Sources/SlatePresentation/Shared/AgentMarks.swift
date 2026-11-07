import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class AgentMarks {
    private(set) var unread: [VaultPath: Date] = [:]

    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let log: any AgentChangeLog
    @ObservationIgnored private var checkedAt: Date

    init(store: any KeyValueStore, log: any AgentChangeLog, now: Date) {
        self.store = store
        self.log = log
        let saved = store.decode(SavedMarks.self, forKey: Keys.marks)
        checkedAt = saved?.checkedAt ?? now
        unread = Dictionary(uniqueKeysWithValues: (saved?.unread ?? [:]).map { (VaultPath(rawValue: $0.key), $0.value) })
        if saved == nil { save() }
    }

    func since(_ path: VaultPath) -> Date? {
        unread[path]
    }

    func refresh() async {
        guard let changes = try? await log.changes(after: checkedAt), let last = changes.last else { return }
        checkedAt = last.date
        for change in changes where unread[change.path] == nil {
            unread[change.path] = change.date
        }
        save()
    }

    func markRead(_ path: VaultPath) {
        guard unread.removeValue(forKey: path) != nil else { return }
        save()
    }

    private func save() {
        let saved = SavedMarks(checkedAt: checkedAt, unread: Dictionary(uniqueKeysWithValues: unread.map { ($0.key.rawValue, $0.value) }))
        store.encode(saved, forKey: Keys.marks)
    }

    private struct SavedMarks: Codable {
        let checkedAt: Date
        let unread: [String: Date]
    }

    private enum Keys {
        static let marks = "agent.unread"
    }
}
