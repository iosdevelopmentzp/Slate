import Foundation
import SlateDomain

extension Ports {
    package static func mock(keyValues: any KeyValueStore = InMemoryKeyValueStore()) -> Ports {
        Ports(keyValues: keyValues, index: MockSearchIndex(), config: MockVaultConfigRepository())
    }
}
