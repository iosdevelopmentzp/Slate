import Foundation

package extension Date {

    var relativeDescription: String {
        relativeDescription(to: .now)
    }

    func relativeDescription(to now: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: self, relativeTo: now)
    }
}
