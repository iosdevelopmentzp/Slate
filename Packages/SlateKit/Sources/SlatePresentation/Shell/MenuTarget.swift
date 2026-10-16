import AppKit

@MainActor
final class MenuTarget: NSObject {
    final class Action: NSObject {
        let run: () -> Void

        init(run: @escaping () -> Void) {
            self.run = run
        }
    }

    @objc func perform(_ sender: NSMenuItem) {
        (sender.representedObject as? Action)?.run()
    }
}
