import Foundation
import Testing
@testable import SlateData

@Suite struct UserDefaultsKeyValueStoreTests {
    private let suiteName = "slate-tests-\(UUID().uuidString)"

    @Test func storesAndRemovesValues() throws {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsKeyValueStore(defaults: defaults)

        store.set("Inbox", forKey: "space")
        store.set([980, 680], forKey: "size")
        store.set(true, forKey: "flag")

        #expect(store.string(forKey: "space") == "Inbox")
        #expect(store.doubles(forKey: "size") == [980, 680])
        #expect(store.bool(forKey: "flag"))

        store.remove(forKey: "space")

        #expect(store.string(forKey: "space") == nil)
    }
}
