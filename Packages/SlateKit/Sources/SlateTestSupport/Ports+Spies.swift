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
            clock: spies.clock,
            attachments: spies.attachments,
            capture: spies.capture,
            workspace: spies.workspace,
            loginItem: spies.loginItem,
            system: spies.system
        )
        return (ports, spies)
    }
}
