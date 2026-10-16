import Foundation
import SlateDomain

extension Ports {
    package static func live(pending: Ports) -> Ports {
        Ports(
            keyValues: UserDefaultsKeyValueStore(),
            index: pending.index,
            config: pending.config
        )
    }
}
