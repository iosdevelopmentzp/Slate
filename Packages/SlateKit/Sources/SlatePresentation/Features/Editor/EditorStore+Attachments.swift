import Foundation
import SlateDomain

extension EditorStore {
    func resolveLink(_ link: String) -> URL? {
        if let url = URL(string: link), url.isFileURL {
            return url
        }
        guard let document, let path = AttachmentPolicy.vaultPath(ofLink: link, from: document.path) else { return nil }
        return vaultRoot.appendingPathComponent(path, isDirectory: false)
    }

    func pasteImage(_ data: Data, fileExtension: String) async {
        guard let path = document?.path else { return }
        do {
            let markdown = try await importAttachment.execute(data: data, fileExtension: fileExtension, for: path)
            insert(markdown)
        } catch {
            report("Cannot add the image", error)
        }
    }

    func pasteFiles(_ urls: [URL]) async {
        guard let path = document?.path, urls.isEmpty == false else { return }
        do {
            let result = try await importAttachment.execute(files: urls, for: path)
            insert(result.text)
            if result.linkedInPlace.isEmpty == false {
                toaster.show("Large files are linked, not copied")
                activity.log("Linked large files in place", detail: result.linkedInPlace.joined(separator: ", "), outcome: .success)
            }
        } catch {
            report("Cannot add the file", error)
        }
    }

    func screenshot(_ mode: CaptureMode) async {
        guard let path = document?.path, isCapturing == false else { return }
        isCapturing = true
        panel.hideForCapture()
        defer {
            panel.showAfterCapture()
            isCapturing = false
        }
        do {
            guard let markdown = try await attachScreenshot.execute(mode, for: path) else { return }
            insert(markdown)
        } catch {
            toaster.show("Screenshot failed")
            activity.log("Screenshot failed. Allow Slate in System Settings → Privacy & Security → Screen Recording.", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func openURL(_ target: String) async {
        if let url = URL(string: target), let scheme = url.scheme?.lowercased(), scheme != "file" {
            await workspace.open(url)
            return
        }
        guard let document, let relative = AttachmentPolicy.vaultPath(ofLink: target, from: document.path) else { return }
        let path = VaultPath(rawValue: relative)
        if path.isNote, let summary = try? await index.summaries(space: nil).first(where: { $0.path == path }) {
            navigator.select(summary.id)
            return
        }
        await workspace.open(vaultRoot.appendingPathComponent(relative, isDirectory: false))
    }

    func openWikilink(_ target: String) async {
        let parsed = WikilinkPolicy.parse(target)
        guard parsed.stem.isEmpty == false else { return }
        do {
            let candidates = try await index.notes(named: parsed.stem)
            let name = parsed.space.map { "\($0)/\(parsed.stem)" } ?? parsed.stem
            if let found = WikilinkPolicy.resolve(name, candidates: candidates, from: document?.path) {
                navigator.select(found.id)
                return
            }
            let space = parsed.space.map(SpaceName.init(rawValue:)) ?? document?.path.space
            let created = try await create.execute(NoteDraft(title: parsed.stem, space: space))
            events.post(.indexUpdated)
            events.post(.noteCreated(created.document.id, caret: created.caret))
            navigator.select(created.document.id)
            toaster.show("Made the note \(created.document.title)")
        } catch {
            report("Cannot open the linked note", error)
        }
    }

    func attachment(_ link: String, quickLook: Bool) async {
        guard let url = resolveLink(link) else { return }
        if quickLook {
            await workspace.quickLook(url)
        } else {
            await workspace.open(url)
        }
    }

    func reveal(_ link: String) async {
        guard let url = resolveLink(link) else { return }
        await workspace.reveal(url)
    }

    func insert(_ markdown: String) {
        guard markdown.isEmpty == false else { return }
        insertionCounter += 1
        insertion = MarkdownInsertion(token: insertionCounter, markdown: markdown)
    }

    private func report(_ title: String, _ error: any Error) {
        toaster.show(title)
        activity.log(title, detail: error.localizedDescription, outcome: .failure)
    }
}
