import Foundation
import MCP
import SlateDomain

struct MCPArgumentCheck {
    let tool: String
    let types: [String: String]
    let required: [String]

    init?(named name: String, alsoAllowed: [String] = []) {
        guard let tool = MCPToolCatalog.tools.first(where: { $0.name == name }) else { return nil }
        self.init(tool, alsoAllowed: alsoAllowed)
    }

    init(_ tool: Tool, alsoAllowed: [String] = []) {
        let schema = tool.inputSchema.objectValue ?? [:]
        var types: [String: String] = [:]
        for (name, property) in schema["properties"]?.objectValue ?? [:] {
            types[name] = property.objectValue?["type"]?.stringValue ?? "string"
        }
        for name in alsoAllowed where types[name] == nil {
            types[name] = "string"
        }
        self.tool = tool.name
        self.types = types
        self.required = (schema["required"]?.arrayValue ?? []).compactMap(\.stringValue)
    }

    func check(_ values: [String: Value], requireAll: Bool = true) throws {
        let given = values.filter { $0.value != .null }
        let unknown = given.keys.filter { types[$0] == nil }.sorted()
        let missing = requireAll ? required.filter { given[$0] == nil } : []
        let wrongType = given.compactMap { name, value -> String? in
            guard let type = types[name], Self.matches(value, type: type) == false else { return nil }
            return "\(name) (\(Self.label(of: type)))"
        }.sorted()
        guard unknown.isEmpty == false || missing.isEmpty == false || wrongType.isEmpty == false else { return }
        throw AgentError.badArguments(tool, unknown: unknown, missing: missing, wrongType: wrongType, accepted: accepted, required: required)
    }

    var accepted: [String] {
        required + types.keys.filter { required.contains($0) == false }.sorted()
    }

    private static func matches(_ value: Value, type: String) -> Bool {
        switch (type, value) {
        case ("string", .string): true
        case ("integer", .int), ("integer", .double): true
        case ("integer", .string(let text)): Int(text) != nil
        case ("boolean", .bool): true
        case ("boolean", .string(let text)): Bool(text.lowercased()) != nil
        case ("array", .array), ("array", .string): true
        case ("string", _), ("integer", _), ("boolean", _), ("array", _): false
        default: true
        }
    }

    private static func label(of type: String) -> String {
        switch type {
        case "integer": "a number"
        case "boolean": "true or false"
        case "array": "a list"
        default: "text"
        }
    }
}
