import Foundation
import SlateDomain

extension EditorStore {
    var isTask: Bool {
        document?.type == NoteType.task.name
    }

    func setStatus(_ status: NoteStatus) async {
        await updateHeader { $0.status = status.rawValue }
    }

    func markDone() async {
        guard let document, document.header.status != nil || isTask else { return }
        await setStatus(.done)
        toaster.show("Marked as Done")
    }

    func insertTemplate(named name: String) async {
        guard let document else { return }
        do {
            let body = try await templates.body(for: name)
            let rendered = TemplateRenderer.render(body, values: TemplateRenderer.values(title: document.title, header: document.header, now: clock.now(), timeZone: clock.timeZone))
            insert(rendered.text)
        } catch {
            activity.log("Cannot read the template", detail: error.localizedDescription, outcome: .failure)
        }
    }
}
