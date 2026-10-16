import Foundation

package protocol LaunchAtLogin: Sendable {
    func status() async -> LoginItemStatus
    func setEnabled(_ enabled: Bool) async throws
}
