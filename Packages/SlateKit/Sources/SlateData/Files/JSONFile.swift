import Foundation
import SlateDomain

enum JSONFile {

    static func object(at url: URL) throws -> [String: Any]? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try FileCoordination.readCoordinated(url)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    static func write(_ object: [String: Any], to url: URL) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        try FileCoordination.writeCoordinated(url, data: data + Data("\n".utf8))
    }
}
