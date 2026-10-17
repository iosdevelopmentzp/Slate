import AppKit

@MainActor
final class MenuTarget: NSObject, NSMenuItemValidation {
    final class Action: NSObject {
        let run: () -> Void
        let isOn: (() -> Bool)?

        init(run: @escaping () -> Void, isOn: (() -> Bool)? = nil) {
            self.run = run
            self.isOn = isOn
        }
    }

    @objc func perform(_ sender: NSMenuItem) {
        (sender.representedObject as? Action)?.run()
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if let isOn = (menuItem.representedObject as? Action)?.isOn {
            menuItem.state = isOn() ? .on : .off
        }
        return true
    }
}
