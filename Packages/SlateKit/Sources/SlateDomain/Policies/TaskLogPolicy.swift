import Foundation

package enum TaskLogPolicy {
    package static let heading = "Log"

    package static func entry(_ text: String, at date: Date, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let stamp = String(format: "%04d-%02d-%02d %02d:%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0, parts.hour ?? 0, parts.minute ?? 0)
        let lines = text.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")
        let first = "- **\(stamp)** \(lines.first ?? "")"
        let rest = lines.dropFirst().map { "  \($0)" }
        return ([first] + rest).joined(separator: "\n")
    }
}
