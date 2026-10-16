import AppKit
import Foundation
import SlateData
import SlateDomain
import SlatePresentation

@MainActor
public final class AppContainer: NSObject {
    private let keyValues: UserDefaultsKeyValueStore
    private let activity = ActivityLog()
    private let firstLaunch = FirstLaunchWindow()
    private var assembly: PresentationAssembly?
    private var windows: AppWindows?
    private init(keyValues: UserDefaultsKeyValueStore) {
        self.keyValues = keyValues
        super.init()
    }

    public static func live() -> AppContainer {
        let container = AppContainer(keyValues: UserDefaultsKeyValueStore())
        Task { @MainActor in
            container.launch()
        }
        return container
    }

    private func launch() {
        NotificationCenter.default.addObserver(self, selector: #selector(willTerminate), name: NSApplication.willTerminateNotification, object: nil)
        if let stored = keyValues.string(forKey: Keys.vaultPath), FileManager.default.fileExists(atPath: stored) {
            open(URL(fileURLWithPath: stored, isDirectory: true))
        } else {
            showFirstLaunch()
        }
    }

    private func showFirstLaunch(problem: String? = nil) {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())
        firstLaunch.show(defaultFolder: documents.appendingPathComponent("Slate", isDirectory: true), problem: problem) { [weak self] folder in
            guard let self else { return }
            open(folder)
        }
    }

    private func open(_ vault: URL) {
        let clock = Date()
        do {
            try VaultBootstrap(root: vault).prepare(now: clock, timeZone: .current)
        } catch {
            showFirstLaunch(problem: "Slate cannot use this folder. \(error.localizedDescription) Choose another folder.")
            return
        }
        keyValues.set(vault.path, forKey: Keys.vaultPath)
        let ports = Ports.live(root: vault, keyValues: keyValues)
        let useCases = UseCases(ports: ports)
        let assembly = PresentationAssembly(ports: ports, useCases: useCases, activity: activity)
        let windows = AppWindows(assembly: assembly)
        self.assembly = assembly
        self.windows = windows
        windows.start()
        Task {
            try? await ports.config.ensureDefaults()
            try? await ports.templates.ensureDefaults()
            assembly.start()
        }
    }

    @objc private func willTerminate(_ notification: Notification) {
        guard let job = assembly?.pendingSave() else { return }
        let done = DispatchSemaphore(value: 0)
        Task.detached {
            await job()
            done.signal()
        }
        _ = done.wait(timeout: .now() + .seconds(3))
    }

    private enum Keys {
        static let vaultPath = "vault.path"
    }
}
