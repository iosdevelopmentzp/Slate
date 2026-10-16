import Foundation
import SlateData
import SlateDomain
import SlateMocks
import SlatePresentation

@MainActor
public final class AppContainer {
    private let ports: Ports
    private let useCases: UseCases
    private let assembly: PresentationAssembly
    private let windows: AppWindows

    private init(ports: Ports, useCases: UseCases, assembly: PresentationAssembly, windows: AppWindows) {
        self.ports = ports
        self.useCases = useCases
        self.assembly = assembly
        self.windows = windows
    }

    public static func live() -> AppContainer {
        let activity = ActivityLog()
        let ports = Ports.live(pending: .mock())
        let useCases = UseCases(ports: ports)
        let assembly = PresentationAssembly(ports: ports, useCases: useCases, activity: activity)
        let windows = AppWindows(assembly: assembly)
        let container = AppContainer(ports: ports, useCases: useCases, assembly: assembly, windows: windows)
        Task { @MainActor in
            windows.start()
        }
        return container
    }
}
