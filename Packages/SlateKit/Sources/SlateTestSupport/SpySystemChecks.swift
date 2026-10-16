import Foundation
import SlateDomain

package final class SpySystemChecks: SystemChecking, @unchecked Sendable {
    private let lock = NSLock()
    private var _checks: [DoctorCheck] = [DoctorCheck(id: "vault", title: "Notes folder", isOK: true, detail: "/vault")]

    package init() {}

    package var result: [DoctorCheck] {
        get { lock.withLock { _checks } }
        set { lock.withLock { _checks = newValue } }
    }

    package func checks() async -> [DoctorCheck] {
        result
    }
}
