import Foundation

package protocol SystemChecking: Sendable {
    func checks() async -> [DoctorCheck]
}
