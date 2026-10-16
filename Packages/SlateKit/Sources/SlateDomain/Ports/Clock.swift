import Foundation

package protocol Clock: Sendable {
    func now() -> Date
    var timeZone: TimeZone { get }
}
