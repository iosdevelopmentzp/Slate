import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class UpdateStore {
    enum State: Equatable {
        case idle
        case available([UpdateCommit])
        case running(UpdateStatus.Phase, startedAt: Date)
        case failed(String)
    }

    static let checkInterval: Duration = .seconds(300)
    static let startWaitPolls = 60

    private(set) var state: State = .idle
    private(set) var log = ""

    @ObservationIgnored private let updater: any AppUpdating
    @ObservationIgnored private let clock: any Clock
    @ObservationIgnored private let toaster: Toaster
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let pollInterval: Duration
    @ObservationIgnored private var build: InstalledBuild?
    @ObservationIgnored private var loop: Task<Void, Never>?
    @ObservationIgnored private var lastError: String?

    init(updater: any AppUpdating, clock: any Clock, toaster: Toaster, activity: ActivityLog, pollInterval: Duration = .seconds(1)) {
        self.updater = updater
        self.clock = clock
        self.toaster = toaster
        self.activity = activity
        self.pollInterval = pollInterval
    }

    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    func start() {
        guard loop == nil else { return }
        loop = Task { [weak self] in
            guard let self else { return }
            await launch()
            while Task.isCancelled == false {
                await check()
                try? await Task.sleep(for: Self.checkInterval)
            }
        }
    }

    func stop() {
        loop?.cancel()
        loop = nil
    }

    func launch() async {
        build = await updater.installed()
        guard let status = await updater.status() else { return }
        switch status.phase {
        case .done:
            await updater.clearStatus()
            if let commit = status.commit, commit == build?.commit {
                toaster.show("Updated to \(String(commit.prefix(7)))")
                activity.log("Updated Slate", detail: commit, outcome: .success)
            }
        case .failed:
            await fail(status.message)
        case .fetching, .building, .installing:
            if await updater.isRunning() {
                await follow()
            } else {
                await fail("The last update stopped before it ended.")
            }
        }
    }

    func check() async {
        guard isRunning == false else { return }
        if build == nil { build = await updater.installed() }
        guard let build else { return }
        do {
            let commits = try await updater.newCommits(for: build)
            lastError = nil
            if case .failed = state, commits.isEmpty == false { return }
            state = commits.isEmpty ? .idle : .available(commits)
        } catch {
            guard lastError != error.localizedDescription else { return }
            lastError = error.localizedDescription
            activity.log("Cannot check for updates", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func checkNow() async {
        await check()
        guard isRunning == false else { return }
        if build == nil {
            toaster.show("Updates work in a copy installed with Scripts/install.sh.")
        } else if state == .idle {
            toaster.show("Slate is up to date.")
        }
    }

    func update() async {
        guard let build, isRunning == false else { return }
        await updater.clearStatus()
        do {
            try await updater.start(build)
        } catch {
            activity.log("Cannot start the update", detail: error.localizedDescription, outcome: .failure)
            state = .failed(error.localizedDescription)
            return
        }
        state = .running(.fetching, startedAt: clock.now())
        await follow()
    }

    func loadLog() async {
        log = await updater.log()
    }

    private func follow() async {
        var waited = 0
        while Task.isCancelled == false {
            let status = await updater.status()
            switch status?.phase {
            case .failed:
                await fail(status?.message)
                return
            case .done:
                if let status { state = .running(.installing, startedAt: status.startedAt) }
                return
            case .some(let phase):
                guard let status else { return }
                state = .running(phase, startedAt: status.startedAt)
                if await updater.isRunning() == false {
                    await fail("The update stopped before it ended.")
                    return
                }
            case nil:
                waited += 1
                if waited > Self.startWaitPolls {
                    await fail("The update did not start.")
                    return
                }
            }
            try? await Task.sleep(for: pollInterval)
        }
    }

    private func fail(_ message: String?) async {
        let text = message ?? "The update failed."
        state = .failed(text)
        activity.log("Update failed", detail: text, outcome: .failure)
        await loadLog()
    }
}
