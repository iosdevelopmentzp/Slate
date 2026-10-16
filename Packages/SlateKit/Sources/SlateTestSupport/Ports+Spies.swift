import SlateDomain

package extension Ports {
    static func spies(keyValues: any KeyValueStore) -> (ports: Ports, spies: PortSpies) {
        let spies = PortSpies()
        let ports = Ports(keyValues: keyValues, index: spies.index, config: spies.config)
        return (ports, spies)
    }
}
