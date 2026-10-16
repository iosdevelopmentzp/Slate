import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class CaptureStore {
    var text = ""
    var space: SpaceName?
    var typeOverride: String?
    private(set) var isSaving = false
    private(set) var focusToken = 0

    @ObservationIgnored private let capture: QuickCaptureUseCase
    @ObservationIgnored private let config: any VaultConfigRepository
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let navigator: Navigator
    @ObservationIgnored private let toaster: Toaster
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents

    init(capture: QuickCaptureUseCase, config: any VaultConfigRepository, store: any KeyValueStore, navigator: Navigator, toaster: Toaster, activity: ActivityLog, events: AppEvents) {
        self.capture = capture
        self.config = config
        self.store = store
        self.navigator = navigator
        self.toaster = toaster
        self.activity = activity
        self.events = events
    }

    var type: String {
        typeOverride ?? QuickCaptureUseCase.suggestedType(for: text, settings: TrackerSettings.load(from: store))
    }

    var canSave: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false && isSaving == false
    }

    func prepare() {
        focusToken += 1
    }

    @discardableResult
    func save(to destination: CaptureInput.Destination, select: Bool = false) async -> NoteDocument? {
        guard canSave else { return nil }
        isSaving = true
        defer { isSaving = false }
        do {
            let input = CaptureInput(text: text, space: type == NoteType.task.name ? nil : space, type: typeOverride ?? type, destination: destination)
            guard let document = try await capture.execute(input) else { return nil }
            text = ""
            typeOverride = nil
            events.post(.indexUpdated)
            events.post(.vaultChanged([document.path]))
            if select {
                navigator.select(document.id)
            }
            toaster.show(destination == .today ? "Added to Today" : "Saved to \(document.path.space?.rawValue ?? "Inbox")")
            return document
        } catch {
            activity.log("Cannot save the quick note", detail: error.localizedDescription, outcome: .failure)
            toaster.show("The quick note was not saved. See Activity.")
            return nil
        }
    }
}
