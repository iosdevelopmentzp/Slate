import Foundation

package enum LogTimestamp {

    package static func text(_ date: Date?) -> String {
        date.map { formatter.string(from: $0) } ?? ""
    }

    package static func time(_ date: Date) -> String {
        shortFormatter.string(from: date)
    }

    private static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
