import Foundation
import SlateDomain

final class OwnWrites: @unchecked Sendable {
    static let window: TimeInterval = 2

    private struct Entry {
        let hash: ContentHash?
        let date: Date
    }

    private let lock = NSLock()
    private var entries: [VaultPath: Entry] = [:]

    func record(_ path: VaultPath, hash: ContentHash?, at date: Date = .now) {
        lock.withLock {
            entries = entries.filter { date.timeIntervalSince($0.value.date) < Self.window }
            entries[path] = Entry(hash: hash, date: date)
        }
    }

    func isOwn(_ path: VaultPath, diskHash: ContentHash?, at date: Date = .now) -> Bool {
        lock.withLock {
            guard let entry = entries[path], date.timeIntervalSince(entry.date) < Self.window else { return false }
            return entry.hash == diskHash
        }
    }
}
