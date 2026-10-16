import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class CaptureStore {
    var text = ""
    var space: SpaceName?
    private(set) var isSaving = false
    private(set) var focusToken = 0

    @ObservationIgnored private let capture: QuickCaptureUseCase
    @ObservationIgnored private let navigator: Navigator
    @ObservationIgnored private let toaster: Toaster
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents

    init(capture: QuickCaptureUseCase, navigator: Navigator, toaster: Toaster, activity: ActivityLog, events: AppEvents) {
        self.capture = capture
        self.navigator = navigator
        self.toaster = toaster
        self.activity = activity
        self.events = events
    }

    var canSave: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false && isSaving == false
    }

    func addFromService(_ selection: String) async {
        let trimmed = selection.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        do {
            guard let document = try await capture.execute(CaptureInput(text: trimmed, type: NoteType.defaultName)) else { return }
            events.post(.indexUpdated)
            toaster.show(savedMessage(for: document))
        } catch {
            activity.log("Cannot add the selected text", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func prepare() {
        focusToken += 1
    }

    @discardableResult
    func save(select: Bool = false) async -> NoteDocument? {
        guard canSave else { return nil }
        isSaving = true
        defer { isSaving = false }
        do {
            guard let document = try await capture.execute(CaptureInput(text: text, space: space, type: NoteType.defaultName)) else { return nil }
            text = ""
            events.post(.indexUpdated)
            events.post(.vaultChanged([document.path]))
            if select {
                navigator.select(document.id)
            }
            toaster.show(savedMessage(for: document))
            return document
        } catch {
            activity.log("Cannot save the quick note", detail: error.localizedDescription, outcome: .failure)
            toaster.show("The quick note was not saved. See Activity in Settings.")
            return nil
        }
    }

    private func savedMessage(for document: NoteDocument) -> String {
        document.path.space.map { "Saved to \($0.rawValue)" } ?? "Saved"
    }
}
