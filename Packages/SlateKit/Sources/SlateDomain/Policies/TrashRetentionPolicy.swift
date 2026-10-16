import Foundation

package enum TrashRetentionPolicy {
    package static func due(_ items: [TrashItem], now: Date, days: Int) -> [TrashItem] {
        guard days > 0 else { return [] }
        let limit = now.addingTimeInterval(-Double(days) * 86_400)
        return items.filter { $0.trashedAt < limit }
    }

    package static func daysLeft(for item: TrashItem, now: Date, days: Int) -> Int {
        let elapsed = now.timeIntervalSince(item.trashedAt) / 86_400
        return max(0, days - Int(elapsed.rounded(.down)))
    }
}
