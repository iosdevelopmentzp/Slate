import Foundation
import MCP
import SlateDomain

struct MCPArguments {
    let values: [String: Value]

    init(_ values: [String: Value]?) {
        self.values = values ?? [:]
    }

    func string(_ key: String) -> String? {
        guard let value = values[key]?.stringValue else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : value
    }

    func raw(_ key: String) -> String? {
        values[key]?.stringValue
    }

    func required(_ key: String) throws -> String {
        guard let value = string(key) else { throw AgentError.missingArgument(key) }
        return value
    }

    func int(_ key: String, default fallback: Int, maximum: Int) -> Int {
        let raw = values[key]?.intValue ?? values[key]?.doubleValue.map(Int.init) ?? values[key]?.stringValue.flatMap(Int.init) ?? fallback
        return min(max(raw, 1), maximum)
    }

    func bool(_ key: String) -> Bool? {
        if let value = values[key]?.boolValue {
            return value
        }
        return values[key]?.stringValue.flatMap { Bool($0.lowercased()) }
    }

    func objects(_ key: String) -> [MCPArguments] {
        var items = values[key]?.arrayValue
        if items == nil, let text = values[key]?.stringValue {
            items = try? JSONDecoder().decode([Value].self, from: Data(text.utf8))
        }
        return (items ?? []).compactMap { $0.objectValue.map(MCPArguments.init) }
    }

    func data(_ key: String) -> Data? {
        if let (_, data) = values[key]?.dataValue {
            return data
        }
        guard var text = string(key) else { return nil }
        if text.hasPrefix("data:"), let comma = text.firstIndex(of: ",") {
            text = String(text[text.index(after: comma)...])
        }
        return Data(base64Encoded: text, options: .ignoreUnknownCharacters)
    }
}
