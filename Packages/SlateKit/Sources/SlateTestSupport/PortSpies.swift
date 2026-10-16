import SlateDomain

package struct PortSpies: Sendable {
    package let index = SpySearchIndex()
    package let config = SpyVaultConfigRepository()

    package init() {}
}
