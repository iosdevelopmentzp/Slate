---
name: add-feature
description: "Add a new screen (tab) to Slate end to end through the package modules: Domain model with package init, repository port with mock, live implementation and spy, Ports and UseCases wiring, an optional use case, the feature store, row model and mapper, one view per file with hover actions, the FeatureID case and registry entry, mapper and store tests, the build, layer check and tests. Use for any 'add a screen / tab / feature / section' request."
---
> Copied from DevHub at bootstrap. Examples still name DevHub features (worktrees, simulators, git commands). Read them as patterns; the Slate types are in `docs/ARCHITECTURE.md`. Update this file when the thing it describes changes in Slate.


# Add Feature

A feature is one screen inside the panel. Ten steps, in this order, through the modules of
`Packages/SlateKit`. Load `/ui-components` for the blocks, `/data-layer` for the repository, `/add-use-case` when
there is logic, `/testing` for the tests. Rules: `docs/ARCHITECTURE.md`. Paths below are relative to
`Packages/SlateKit/Sources/`.

## 1. Model — `SlateDomain/Models/Device.swift`

One entity per file. Plain value type, `Sendable`, `let id`, `var` fields, an enum for state. No colour, no icon
chosen by the app, no display string. Nonisolated is the module default, so no `nonisolated`. Other modules build
it, so it is `package` with an explicit `package init` in declaration order.

```swift
import Foundation

package struct Device: Identifiable, Hashable, Sendable {
    package enum State: Hashable, Sendable {
        case connected
        case disconnected
    }

    package let id: String
    package var name: String
    package var state: State
    package var lastSeen: Date

    package init(id: String, name: String, state: State, lastSeen: Date) {
        self.id = id
        self.name = name
        self.state = state
        self.lastSeen = lastSeen
    }
}
```

## 2. Port — `SlateDomain/Repositories/DeviceRepository.swift`

```swift
package protocol DeviceRepository: Sendable {
    func list() async throws -> [Device]
    func reconnect(id: String) async throws
}
```

Methods are `async throws`; long work returns `AsyncThrowingStream`. No arguments, exit codes or raw output in a
port. Requirements carry no access keyword.

## 3. Mock, live, spy, `Ports`

- `SlateMocks/MockDeviceRepository.swift` (internal): returns `MockData.devices` (add
  `SlateMocks/MockData+Devices.swift` with `package static let devices`, four to six rows, one per state) and sleeps
  a little on actions.
- `SlateData/<Domain>/<Technology>DeviceRepository.swift` (internal): takes `ShellRunner` (or a runner such as
  `SimctlRunner`) in `init`, parses through a pure parser in its own file with private DTOs.
- `SlateTestSupport/SpyDeviceRepository.swift`: a `Call` enum, scripted `listResult` and `reconnectError`, a lock.
  Copy the shape of `SpyWorktreeRepository`.
- One field in `Ports` (`SlateDomain/Assembly/Ports.swift`, also in its `package init`), one line in
  `Ports.live(root:keyValues:)` (`SlateData/Assembly/Ports+Live.swift`), one in `Ports.mock()`
  (`SlateMocks/Ports+Mock.swift`), one in `PortSpies` and in `Ports.spies(keyValues:)` (`SlateTestSupport/`).

## 4. Use case — only when there is logic

A rule → `SlateDomain/Policies/DevicePolicy.swift`. A multi-step sequence or two ports →
`SlateDomain/UseCases/ReconnectDeviceUseCase.swift` plus one field and one line in `UseCases(ports:)`
(`SlateDomain/Assembly/UseCases.swift`). A single port call needs no use case. See `/add-use-case`.

## 5. Store — `SlatePresentation/Features/Devices/DevicesStore.swift`

```swift
import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class DevicesStore {
    private(set) var devices: [Device] = []
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var busyIDs: Set<Device.ID> = []

    @ObservationIgnored private let repository: any DeviceRepository
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(repository: any DeviceRepository, session: ProjectSession, activity: ActivityLog, events: AppEvents) {
        self.repository = repository
        self.session = session
        self.activity = activity
        self.events = events
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .projectChanged = event else { return }
            Task { await self.refresh() }
        }
    }

    func refresh() async {
        await refreshTask.run { [weak self] in
            guard let self else { return }
            isLoading = true
            defer { isLoading = false }
            do {
                let loaded = try await repository.list()
                try Task.checkCancellation()
                devices = loaded
                error = nil
            } catch is CancellationError {
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func reconnect(id: Device.ID) {
        busyIDs.insert(id)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await repository.reconnect(id: id)
                activity.log("Reconnected", detail: id, outcome: .success)
            } catch {
                activity.log("Reconnect failed", detail: error.localizedDescription, outcome: .failure)
            }
            busyIDs.remove(id)
            await refresh()
        }
    }
}
```

Rules:
- The store owns the feature state and every mutation. It takes ports, use cases, shared objects and lookup
  protocols in `init`; never another feature's concrete store, never `UserDefaults` (take a `KeyValueStore`),
  never a static service, never `import SwiftUI`.
- Something other features show changed: post an `AppEvent`. Something other features changed that this one
  shows: subscribe. A refresh uses `RefreshTask`; an action catches its error and logs it.
- Anything the user would want to see later calls `activity.log(_:detail:outcome:)`.
- The store stays internal (no `package`): only SlatePresentation and its tests use it.
- Wire it in `SlatePresentation/Shared/PresentationAssembly.swift`: `let devices: DevicesStore`, one line in `init`
  (`devices = DevicesStore(repository: ports.devices, session: session, activity: activity, events: events)`),
  `.environment(assembly.devices)` in `Shared/View+Inject.swift`; seed sample state in
  `PresentationAssembly+Preview.swift` when the mock repository alone is not enough.

## 6. Row model and mapper — `SlatePresentation/Features/Devices/Models/`

```swift
import SlateDomain
import SlateUI

struct DeviceRowModel: Identifiable, Equatable {
    let id: Device.ID
    var title: String
    var subtitle: String
    var icon: String
    var iconTint: Tint
    var tags: [TagModel]
    var canReconnect: Bool
    var isBusy: Bool

    static let preview = DeviceRowModel(id: "1", title: "iPhone 16", subtitle: "2 h ago", icon: "iphone", iconTint: .blue, tags: [TagModel("connected", tint: .green, systemImage: "checkmark")], canReconnect: false, isBusy: false)
}

enum DeviceRowMapper {
    static func model(for device: Device, isBusy: Bool) -> DeviceRowModel {
        DeviceRowModel(
            id: device.id,
            title: device.name,
            subtitle: device.lastSeen.relativeDescription,
            icon: "iphone",
            iconTint: device.state == .connected ? .blue : .secondary,
            tags: [device.state == .connected ? TagModel("connected", tint: .green, systemImage: "checkmark") : TagModel("offline", tint: .orange)],
            canReconnect: device.state == .disconnected && isBusy == false,
            isBusy: isBusy
        )
    }
}
```

Colour, icon, text, hint and enabled flags are chosen here, never in a view. Sorting and grouping too.

## 7. Views — `SlatePresentation/Features/Devices/Views/`

One view per file: `DevicesView.swift`, `DevicesToolbar.swift`, `DeviceRow.swift`.

```swift
import SwiftUI
import SlateDomain
import SlateUI

struct DevicesView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(DevicesStore.self) private var store

    private var models: [DeviceRowModel] {
        store.devices
            .filter { session.matchesSearch($0.name) }
            .map { DeviceRowMapper.model(for: $0, isBusy: store.busyIDs.contains($0.id)) }
    }

    var body: some View {
        VStack(spacing: 0) {
            DevicesToolbar()
            Divider()
            ListState(
                failure: store.error.map { ListMessage.failure("Cannot read devices", description: $0) { Task { await store.refresh() } } },
                isLoading: store.devices.isEmpty && store.isLoading,
                loadingTitle: "Reading devices…",
                empty: store.devices.isEmpty ? ListMessage("No devices", systemImage: "ipad.and.iphone", description: "Connect a device.") : nil,
                noResultsFor: session.searchText
            ) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(models) { model in
                            DeviceRow(model: model) { store.reconnect(id: model.id) }
                            if model.id != models.last?.id {
                                Divider().padding(.leading, 56)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .background(Theme.surface)
    }
}

#Preview {
    DevicesView()
        .previewEnvironment()
}
```

```swift
struct DeviceRow: View {
    @Environment(Toaster.self) private var toaster

    let model: DeviceRowModel
    let onReconnect: () -> Void

    var body: some View {
        RowContainer { isHovered in
            HStack(spacing: 10) {
                IconTile(systemImage: model.icon, tint: model.iconTint.color, size: 32)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(model.title).font(.callout.weight(.semibold)).lineLimit(1)
                        ForEach(model.tags, id: \.self) { ModelTag(model: $0) }
                    }
                    Text(model.subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                HStack(spacing: 2) {
                    IconButton(systemImage: "arrow.clockwise", help: "Reconnect") { onReconnect() }
                        .disabled(model.canReconnect == false)
                    OverflowMenu {
                        Button("Copy UDID", systemImage: "doc.on.doc") { toaster.copy(model.id) }
                    }
                }
                .opacity(isHovered ? 1 : 0)
            }
        }
    }
}

#Preview {
    DeviceRow(model: .preview, onReconnect: {})
        .previewEnvironment()
        .frame(width: 720)
}
```

A row reads `Toaster` and `AppActions` at most. An action that crosses features (switch tab, then run) is a method
on `SlatePresentation/Shared/AppActions.swift`, never `navigator.show` plus a store call in a view. Destructive actions
use `InlineConfirmation` inside the row; no alerts, no sheets.

## 8. Register — `SlatePresentation/Shell/`

Add a case to `FeatureID` and one line to `FeatureRegistry.all` (position = tab order):

```swift
Feature(id: .devices, title: "Devices", systemImage: "ipad.and.iphone", searchPrompt: "Search devices") { DevicesView() },
```

`showsInTabBar: false` for a screen opened from a button (`actions.openSettings()` style method on `AppActions`).

## 9. Tests — `Packages/SlateKit/Tests/`

- `SlatePresentationTests/Mappers/Devices/DeviceRowMapperTests.swift`: one `@Test` per state, pinning icon, tint,
  tags and enabled flags. No assertion on `relativeDescription` text.
- `SlatePresentationTests/Stores/Devices/DevicesStoreTests.swift`: add `lazy var devices = DevicesStore(...)` to
  `Stores/Support/StoreHarness.swift`; test refresh (success, failure, `.projectChanged`), `reconnect` (spy call,
  busy IDs, activity line). `waitUntil` for the `Task` inside `reconnect`.
- `SlateDataTests/<Domain>/DeviceListParserTests.swift` with a fixture in `Fixtures/DeviceListFixture.swift`.
- A use case or policy gets its suite in `SlateDomainTests/`.

See `/testing` for the shapes.

## 10. Build and test

```sh
Scripts/build.sh
Scripts/test.sh
```

`layers: ok`, the app path, zero errors, zero warnings; one passing `Test run with` line. Then `/update-docs`.

## Checklist

- [ ] Model in `SlateDomain/Models/`, `package` with an explicit `package init`, enum for status, no UI data
- [ ] Port in `SlateDomain/Repositories/`; mock in `SlateMocks/`, live in `SlateData/<Domain>/`, spy in `SlateTestSupport/`
- [ ] Field in `Ports`, lines in `Ports.live`, `Ports.mock`, `PortSpies` and `Ports.spies(keyValues:)`
- [ ] Use case or policy only where there is logic, wired in `UseCases(ports:)`
- [ ] Store takes everything in `init`; wired in `PresentationAssembly`, `View+Inject` and `StoreHarness`
- [ ] Row model and mapper in `Models/`; no colour, icon or text chosen in a view
- [ ] One view per file in `Views/`; screen filters with `session.matchesSearch`; `ListState` for the empty states
- [ ] Row actions appear on hover through `RowContainer`; cross-feature actions through `AppActions`
- [ ] `#Preview` on the screen and on every row
- [ ] `FeatureID` case and `FeatureRegistry.all` line
- [ ] Tests for the mapper, the store, the parser and any use case
- [ ] `Scripts/build.sh` and `Scripts/test.sh` clean, `CHANGELOG.md` and `docs/STATUS.md` updated
