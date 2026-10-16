import SlateDomain

package extension Ports {
    static func spies(keyValues: any KeyValueStore = SpyKeyValueStore()) -> (ports: Ports, spies: PortSpies) {
        let spies = PortSpies()
        let ports = Ports(
            keyValues: keyValues,
            files: spies.files,
            index: spies.index,
            builder: spies.builder,
            watcher: spies.watcher,
            trash: spies.trash,
            templates: spies.templates,
            config: spies.config,
            clock: spies.clock
        )
        return (ports, spies)
    }
}
