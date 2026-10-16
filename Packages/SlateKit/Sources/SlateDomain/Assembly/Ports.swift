import Foundation

package struct Ports: Sendable {
    package let keyValues: any KeyValueStore
    package let index: any SearchIndex
    package let config: any VaultConfigRepository

    package init(keyValues: any KeyValueStore, index: any SearchIndex, config: any VaultConfigRepository) {
        self.keyValues = keyValues
        self.index = index
        self.config = config
    }
}
