import Foundation
import SlateDomain

struct FileTemplateRepository: TemplateRepository {
    static let folderName = "_templates"

    let root: URL

    private var templates: URL {
        root.appendingPathComponent(Self.folderName, isDirectory: true)
    }

    func body(for type: String) async throws -> String {
        let url = templates.appendingPathComponent("\(type).md")
        guard FileManager.default.fileExists(atPath: url.path) else {
            return BuiltInTemplates.bodies[type] ?? ""
        }
        return String(decoding: try FileCoordination.readCoordinated(url), as: UTF8.self)
    }

    func ensureDefaults() async throws {
        for (type, body) in BuiltInTemplates.bodies {
            let url = templates.appendingPathComponent("\(type).md")
            guard FileManager.default.fileExists(atPath: url.path) == false else { continue }
            try FileCoordination.writeCoordinated(url, data: Data(body.utf8))
        }
    }
}
