import Observation
import SlateDomain

@MainActor
@Observable
final class Toaster {
    static let duration: Duration = .seconds(4)

    @ObservationIgnored private let write: (String) -> Void

    private(set) var text: String?

    @ObservationIgnored private var hideTask: Task<Void, Never>?

    init(write: @escaping (String) -> Void) {
        self.write = write
    }

    func copy(_ value: String, label: String) {
        write(value)
        show("\(label) copied")
    }

    func show(_ message: String) {
        hideTask?.cancel()
        text = message
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: Self.duration)
            guard Task.isCancelled == false else { return }
            guard let self else { return }
            text = nil
        }
    }

    func dismiss() {
        hideTask?.cancel()
        text = nil
    }
}
