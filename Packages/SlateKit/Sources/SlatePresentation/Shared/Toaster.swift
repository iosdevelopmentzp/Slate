import Observation
import SlateDomain

@MainActor
@Observable
final class Toaster {
    static let duration: Duration = .seconds(4)
    static let undoDuration: Duration = .seconds(5)

    @ObservationIgnored private let write: (String) -> Void

    private(set) var text: String?
    @ObservationIgnored private(set) var action: ToastAction?

    @ObservationIgnored private var hideTask: Task<Void, Never>?

    init(write: @escaping (String) -> Void) {
        self.write = write
    }

    var actionTitle: String? {
        text == nil ? nil : action?.title
    }

    func copy(_ value: String, label: String) {
        write(value)
        show("\(label) copied")
    }

    func show(_ message: String, action: ToastAction? = nil) {
        hideTask?.cancel()
        self.action = action
        text = message
        let duration = action == nil ? Self.duration : Self.undoDuration
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard Task.isCancelled == false else { return }
            guard let self else { return }
            dismiss()
        }
    }

    func performAction() {
        let action = action
        dismiss()
        action?.perform()
    }

    func dismiss() {
        hideTask?.cancel()
        action = nil
        text = nil
    }
}
