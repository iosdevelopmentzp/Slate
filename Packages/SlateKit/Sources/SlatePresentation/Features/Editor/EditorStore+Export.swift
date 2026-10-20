import Foundation
import SlateDomain

extension EditorStore {
    func exportHTML() async {
        guard let (title, body, folder) = await exportSource() else { return }
        let page = exporter.html(title: title, body: body, folder: folder)
        await saveExport(Data(page.utf8), name: "\(title).html")
    }

    func exportPDF() async {
        guard let (title, body, folder) = await exportSource() else { return }
        do {
            let data = try await exporter.pdf(title: title, body: body, folder: folder)
            await saveExport(data, name: "\(title).pdf")
        } catch {
            activity.log("Cannot make the PDF", detail: error.localizedDescription, outcome: .failure)
            toaster.show("Cannot make the PDF. See Activity.")
        }
    }

    private func exportSource() async -> (String, String, URL)? {
        await flush()
        guard let document else { return nil }
        let folder = document.path.folder.isEmpty ? vaultRoot : vaultRoot.appendingPathComponent(document.path.folder, isDirectory: true)
        return (document.title, ExportMarkdownPolicy.prepared(text), folder)
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
