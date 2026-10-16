import Foundation
import SlateDomain

struct MockLoginItem: LaunchAtLogin {
    func status() async -> LoginItemStatus {
        .disabled
    }

    func setEnabled(_ enabled: Bool) async throws {}
}
