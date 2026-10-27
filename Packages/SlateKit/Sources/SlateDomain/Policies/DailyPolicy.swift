import Foundation

package enum DailyPolicy {
    package static let logHeading = "Log"
    package static let carriedHeading = "Carried over"

    package static func stem(for date: Date, timeZone: TimeZone) -> String {
        let parts = calendar(timeZone).dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    package static func date(fromStem stem: String, timeZone: TimeZone) -> Date? {
        let parts = stem.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, stem.count == 10 else { return nil }
        return calendar(timeZone).date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    package static func isDailyStem(_ stem: String) -> Bool {
        stem.count == 10 && stem.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil
    }

    package static func day(_ offset: Int, from stem: String, timeZone: TimeZone) -> String? {
        guard let date = date(fromStem: stem, timeZone: timeZone), let moved = calendar(timeZone).date(byAdding: .day, value: offset, to: date) else { return nil }
        return self.stem(for: moved, timeZone: timeZone)
    }

    package static func logLine(_ text: String, at date: Date, timeZone: TimeZone) -> String {
        let parts = calendar(timeZone).dateComponents([.hour, .minute], from: date)
        let time = String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
        let lines = text.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n").filter { $0.trimmingCharacters(in: .whitespaces).isEmpty == false }
        let first = "- \(time) \(lines.first ?? "")"
        let rest = lines.dropFirst().map { "  \($0)" }
        return ([first] + rest).joined(separator: "\n")
    }

    package static func carryOver(from body: String) -> [String] {
        MarkdownText.proseLines(of: body).compactMap { line in
            guard let parsed = TodoLinePolicy.parse(line.text), parsed.isDone == false, parsed.text.isEmpty == false else { return nil }
            return "- [ ] \(parsed.text)"
        }
    }

    package static func previousStem(before stem: String, among stems: [String]) -> String? {
        stems.filter { isDailyStem($0) && $0 < stem }.max()
    }

    package static func carriedBlock(_ items: [String]) -> String {
        "## \(carriedHeading)\n\n" + items.joined(separator: "\n") + "\n\n"
    }

    private static func calendar(_ timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
