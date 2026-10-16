import Foundation

package enum TemplateRenderer {
    package struct Rendered: Hashable, Sendable {
        package let text: String
        package let caret: Int

        package init(text: String, caret: Int) {
            self.text = text
            self.caret = caret
        }
    }

    package static let cursor = "{{cursor}}"

    package static func render(_ template: String, values: [String: String]) -> Rendered {
        var text = template
        for (key, value) in values {
            text = text.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        guard let range = text.range(of: cursor) else {
            return Rendered(text: text, caret: text.utf16.count)
        }
        let caret = text[..<range.lowerBound].utf16.count
        text.removeSubrange(range)
        text = text.replacingOccurrences(of: cursor, with: "")
        return Rendered(text: text, caret: caret)
    }

    package static func values(title: String, header: NoteHeader, now: Date, timeZone: TimeZone) -> [String: String] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .weekday], from: now)
        let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return [
            "title": title,
            "date": String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0),
            "time": String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0),
            "datetime": FrontmatterWriter.date(now, timeZone: timeZone),
            "weekday": weekdays[((parts.weekday ?? 1) - 1) % 7],
            "ticket": header.ticket ?? "",
            "branch": header.branch ?? "",
            "mr": header.mr ?? "",
            "language": header.language ?? "",
        ]
    }
}
