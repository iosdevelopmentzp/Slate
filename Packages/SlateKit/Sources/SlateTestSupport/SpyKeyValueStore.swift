import Foundation
import SlateDomain

package final class SpyKeyValueStore: KeyValueStore, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: Any] = [:]

    package init() {}

    package func string(forKey key: String) -> String? { value(key) as? String }
    package func strings(forKey key: String) -> [String]? { value(key) as? [String] }
    package func bool(forKey key: String) -> Bool { value(key) as? Bool ?? false }
    package func integer(forKey key: String) -> Int { value(key) as? Int ?? 0 }
    package func doubles(forKey key: String) -> [Double]? { value(key) as? [Double] }
    package func stringMap(forKey key: String) -> [String: String]? { value(key) as? [String: String] }
    package func data(forKey key: String) -> Data? { value(key) as? Data }
    package func set(_ value: String?, forKey key: String) { store(value, key) }
    package func set(_ value: [String], forKey key: String) { store(value, key) }
    package func set(_ value: Bool, forKey key: String) { store(value, key) }
    package func set(_ value: Int, forKey key: String) { store(value, key) }
    package func set(_ value: [Double], forKey key: String) { store(value, key) }
    package func set(_ value: [String: String], forKey key: String) { store(value, key) }
    package func set(_ value: Data?, forKey key: String) { store(value, key) }
    package func remove(forKey key: String) { store(nil, key) }

    private func value(_ key: String) -> Any? {
        lock.withLock { values[key] }
    }

    private func store(_ value: Any?, _ key: String) {
        lock.withLock { values[key] = value }
    }
}
