import Foundation

package struct AgentGuideWriter: Sendable {
    let files: any VaultFileStore

    package init(files: any VaultFileStore) {
        self.files = files
    }

    @discardableResult
    package func execute() async throws -> [VaultPath] {
        var written: [VaultPath] = []
        for name in AgentGuide.fileNames {
            let path = VaultPath(rawValue: name)
            guard try await files.meta(path) != nil else {
                _ = try await files.create(path, data: Data(AgentGuide.block.utf8))
                written.append(path)
                continue
            }
            let contents = try await files.read(path)
            let text = String(decoding: contents.data, as: UTF8.self)
            let merged = Self.merged(text, block: AgentGuide.block)
            guard merged != text else { continue }
            _ = try await files.write(path, data: Data(merged.utf8), expected: contents.hash)
            written.append(path)
        }
        return written
    }

    package static func merged(_ existing: String, block: String) -> String {
        guard let start = existing.range(of: AgentGuide.begin),
              let finish = existing.range(of: AgentGuide.end, range: start.upperBound..<existing.endIndex)
        else {
            guard existing.isEmpty == false else { return block }
            let separator = existing.hasSuffix("\n\n") ? "" : (existing.hasSuffix("\n") ? "\n" : "\n\n")
            return existing + separator + block
        }
        var after = finish.upperBound
        if after < existing.endIndex, existing[after] == "\n" {
            after = existing.index(after: after)
        }
        return String(existing[..<start.lowerBound]) + block + String(existing[after...])
    }
}
