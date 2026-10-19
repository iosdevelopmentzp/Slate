import AppKit
import Foundation
import SlateData
import SlateDomain
import SlatePresentation

@MainActor
public final class AppContainer: NSObject, NSApplicationDelegate {
    private let keyValues: UserDefaultsKeyValueStore
    private let activity = ActivityLog()
    private let firstLaunch = FirstLaunchWindow()
    private var assembly: PresentationAssembly?
    private var windows: AppWindows?
    private var services: ServicesProvider?
    private var pendingURLs: [URL] = []
    override public init() {
        keyValues = UserDefaultsKeyValueStore()
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        launch()
    }

    public func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handle(url)
        }
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard let windows else { return true }
        windows.showWindow()
        return false
    }

    public func applicationWillTerminate(_ notification: Notification) {
        guard let job = assembly?.pendingSave() else { return }
        let done = DispatchSemaphore(value: 0)
        Task.detached {
            await job()
            done.signal()
        }
        _ = done.wait(timeout: .now() + .seconds(3))
    }

    private func launch() {
        let services = ServicesProvider { [weak self] text in
            guard let self else { return }
            windows?.addFromService(text)
        }
        self.services = services
        NSApp.servicesProvider = services
        NSUpdateDynamicServices()
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
        let ports: Ports
        do {
            ports = try Ports.live(root: vault, support: VaultSupportFolder.url(for: vault), keyValues: keyValues, recorder: ActivityRecorder(log: activity))
        } catch {
            showFirstLaunch(problem: "Slate cannot prepare its search data for this folder. \(error.localizedDescription)")
            return
        }
        keyValues.set(vault.path, forKey: Keys.vaultPath)
        let useCases = UseCases(ports: ports)
        let assembly = PresentationAssembly(ports: ports, useCases: useCases, activity: activity, vaultRoot: vault)
        let windows = AppWindows(assembly: assembly)
        windows.onChangeVault = { [weak self] folder in
            guard let self else { return }
            switchVault(to: folder, from: vault)
        }
        self.assembly = assembly
        self.windows = windows
        windows.start()
        let queued = pendingURLs
        pendingURLs = []
        for url in queued {
            handle(url)
        }
        Task {
            try? await ports.config.ensureDefaults()
            try? await useCases.agentGuide.execute()
            assembly.start()
        }
    }

    private func switchVault(to folder: URL, from current: URL) {
        guard folder.standardizedFileURL != current.standardizedFileURL else { return }
        Task {
            await assembly?.flush()
            windows?.stop()
            assembly?.stop()
            windows = nil
            assembly = nil
            open(folder)
        }
    }

    private func handle(_ url: URL) {
        guard let windows else {
            pendingURLs.append(url)
            return
        }
        guard let command = URLCommandParser.parse(url) else { return }
        windows.handle(command)
    }

    private enum Keys {
        static let vaultPath = "vault.path"
    }
}
