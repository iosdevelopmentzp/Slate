import Foundation
import SlateDomain
import SlateUI

enum VersionRowMapper {
    static let agentBadge = TagModel("Agent", tint: .purple, systemImage: "sparkles")

    static func model(for snapshot: Snapshot, now: Date) -> VersionRowModel {
        let date = snapshot.date.formatted(date: .abbreviated, time: .shortened)
        if let name = snapshot.versionName {
            return VersionRowModel(id: snapshot.hash, title: name, detail: date, isNamed: true, badge: nil)
        }
        return VersionRowModel(
            id: snapshot.hash,
            title: snapshot.date.relativeDescription(to: now),
            detail: date,
            isNamed: false,
            badge: snapshot.isByAgent ? agentBadge : nil
        )
    }

    static func summary(of change: SnapshotChange) -> String {
        if let name = change.snapshot.versionName { return name }
        let message = change.snapshot.message
        if change.snapshot.isByAgent {
            let rest = message.dropFirst(Snapshot.agentPrefix.count)
            let parts = rest.split(separator: " ", maxSplits: 1).map(String.init)
            return parts.count == 2 ? "\(tool(parts[0])) \(parts[1])" : "Changed by an agent"
        }
        if message.hasPrefix("before restore") { return "Before a restore" }
        if message.hasPrefix("history") { return "History cleared" }
        return "Saved by Slate"
    }

    private static func tool(_ name: String) -> String {
        switch name {
        case "create_note", "start_task": "Created"
        case "log_progress": "Logged progress in"
        case "set_task_status": "Changed the status of"
        case "add_file": "Added"
        case "attach_image": "Added an image to"
        case "move_note": "Moved"
        case "trash_note": "Moved to the Trash:"
        default: "Changed"
        }
    }
}
