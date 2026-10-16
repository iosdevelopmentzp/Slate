import Foundation
import SlateData
import SlateDomain

struct CLIContainer {
    static let appDomain = "local.slate.app"

    let root: URL
    let ports: Ports
    let useCases: UseCases
    let shell: ShellRunner

    init(options: VaultOptions) throws {
        let keyValues = UserDefaultsKeyValueStore(suite: Self.appDomain) ?? UserDefaultsKeyValueStore()
        let path = options.vault ?? ProcessInfo.processInfo.environment["SLATE_VAULT"] ?? keyValues.string(forKey: "vault.path")
        guard let path, FileManager.default.fileExists(atPath: (path as NSString).expandingTildeInPath) else { throw CLIError.noVault }
        root = URL(fileURLWithPath: (path as NSString).expandingTildeInPath, isDirectory: true)
        ports = try Ports.live(root: root, support: VaultSupportFolder.url(for: root), keyValues: keyValues, recorder: NoopRecorder())
        useCases = UseCases(ports: ports)
        shell = ShellRunner(recorder: NoopRecorder())
    }

    func refreshIndex() async throws {
        _ = try await useCases.reindex.execute(.all)
    }

    func openInApp(_ query: [URLQueryItem], route: String) async throws {
        var components = URLComponents()
        components.scheme = URLCommandParser.scheme
        components.host = route
        components.queryItems = query
        guard let url = components.url else { return }
        _ = try await shell.run("/usr/bin/open", [url.absoluteString], cwd: nil)
    }

    func absolutePath(_ path: VaultPath) -> String {
        root.appendingPathComponent(path.rawValue).path
    }

    func find(ticket: String?, title: String?, id: String?) async throws -> NoteSummary? {
        if let ticket {
            return try await ports.index.notes(withTicket: ticket).first
        }
        if let id {
            return try await ports.index.summary(id: NoteID(rawValue: id))
        }
        if let title {
            let summaries = try await ports.index.summaries(space: nil)
            return summaries.first { StemPolicy.isSame($0.title, title) } ?? summaries.first { StemPolicy.isSame($0.stem, StemPolicy.stem(forTitle: title)) }
        }
        return nil
    }

    static func print(_ summaries: [NoteSummary], json: Bool, root: URL) {
        if json {
            let objects = summaries.map { summary -> [String: Any] in
                var object: [String: Any] = ["id": summary.id.rawValue, "path": root.appendingPathComponent(summary.path.rawValue).path, "title": summary.title, "type": summary.type, "updated": ISO8601DateFormatter().string(from: summary.updated)]
                object["ticket"] = summary.ticket
                object["status"] = summary.status?.rawValue
                object["space"] = summary.space?.rawValue
                return object
            }
            let data = (try? JSONSerialization.data(withJSONObject: objects, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])) ?? Data()
            Swift.print(String(decoding: data, as: UTF8.self))
            return
        }
        for summary in summaries {
            let ticket = summary.ticket.map { "\($0)  " } ?? ""
            Swift.print("\(ticket)\(summary.title)\t\(summary.path.rawValue)")
        }
    }
}
