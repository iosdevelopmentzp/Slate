import Foundation
import SlateUI

enum SaveStatusText {
    static let justNowInterval: TimeInterval = 60

    static func text(for state: SaveState, now: Date) -> String? {
        switch state {
        case .idle:
            nil
        case .saving:
            "saving…"
        case .saved(let date):
            now.timeIntervalSince(date) < justNowInterval ? "saved just now" : "saved \(date.relativeDescription(to: now))"
        case .failed:
            "not saved, see Activity"
        }
    }
}
