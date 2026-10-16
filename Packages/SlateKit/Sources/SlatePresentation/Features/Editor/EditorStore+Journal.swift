import Foundation
import SlateDomain

extension EditorStore {
    static let journalDelay: Duration = .seconds(1)

    func scheduleJournal() {
        guard journalTask == nil else { return }
        journalTask = Task { [weak self] in
            try? await Task.sleep(for: Self.journalDelay)
            guard Task.isCancelled == false, let self else { return }
            journalTask = nil
            await writeJournal()
        }
    }

    func writeJournal() async {
        guard let document, isDirty else { return }
        do {
            try await journal.save(JournalEntry(noteID: document.id, path: document.path, text: text, savedAt: clock.now()))
        } catch {
            activity.log("Cannot keep a copy of the unsaved text", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func clearJournal(_ id: NoteID) {
        journalTask?.cancel()
        journalTask = nil
        Task {
            try? await journal.clear(id)
        }
    }

    func checkJournal(for document: NoteDocument) async {
        let entry = try? await journal.entry(for: document.id)
        guard self.document?.id == document.id else { return }
        if JournalPolicy.shouldOffer(entry, for: document) {
            recovered = entry
        } else if entry != nil {
            clearJournal(document.id)
        }
    }

    func restoreRecovered() {
        guard let entry = recovered, document?.id == entry.noteID else { return }
        recovered = nil
        text = entry.text
    }

    func discardRecovered() {
        guard let entry = recovered else { return }
        recovered = nil
        clearJournal(entry.noteID)
    }

    func openBoth() async {
        guard let current = document else { return }
        let mine = text
        let title = ConflictCopyPolicy.title(for: current.title, at: clock.now(), timeZone: clock.timeZone)
        do {
            let copy = try await create.execute(NoteDraft(title: title, type: current.type, space: current.path.space, body: mine))
            events.post(.indexUpdated)
            await takeTheirs()
            toaster.show("Your text is in \(copy.document.title)")
        } catch {
            activity.log("Cannot keep both versions", detail: error.localizedDescription, outcome: .failure)
        }
    }
}
