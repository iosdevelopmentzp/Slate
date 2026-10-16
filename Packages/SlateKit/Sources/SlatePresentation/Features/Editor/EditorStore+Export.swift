import Foundation
import SlateDomain

extension EditorStore {
    func copyMarkdown() {
        guard document != nil else { return }
        toaster.copy(text, label: "Markdown")
    }

    func copySlack() {
        guard document != nil else { return }
        toaster.copy(SlackFormatPolicy.format(text), label: "Text for Slack")
    }

    func saveHTML() async {
        guard let document else { return }
        let page = exporter.html(title: document.title, body: text)
        await saveExport(Data(page.utf8), name: "\(document.title).html")
    }

    func savePDF() async {
        guard let document else { return }
        do {
            let data = try await exporter.pdf(title: document.title, body: text)
            await saveExport(data, name: "\(document.title).pdf")
        } catch {
            activity.log("Cannot make the PDF", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func run(_ action: ActionDefinition) async {
        await flush()
        guard let document else { return }
        do {
            let result = try await runAction.execute(action, on: document, vault: vaultRoot)
            guard result.succeeded else {
                activity.log(action.title, detail: result.output.isEmpty ? "Exited with code \(result.exitCode)." : result.output, outcome: .failure)
                toaster.show("\(action.title) failed. See Activity.")
                return
            }
            switch action.output {
            case .activity:
                activity.log(action.title, detail: result.output, outcome: .success)
                toaster.show("Done: \(action.title)")
            case .clipboard:
                toaster.copy(result.output.trimmingCharacters(in: .newlines), label: "Result")
            case .appendToNote:
                if let appended = result.appended {
                    events.post(.vaultChanged([appended.path]))
                }
                toaster.show("Added the result to the note")
            }
        } catch {
            activity.log(action.title, detail: error.localizedDescription, outcome: .failure)
            toaster.show("\(action.title) failed. See Activity.")
        }
    }

    private func saveExport(_ data: Data, name: String) async {
        do {
            let url = try await exporter.saveToDownloads(data, fileName: name)
            await workspace.reveal(url)
            toaster.show("Saved \(url.lastPathComponent) to Downloads")
        } catch {
            activity.log("Cannot save the file", detail: error.localizedDescription, outcome: .failure)
        }
    }
}
