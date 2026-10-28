import Foundation

package struct WriteTextFileUseCase: Sendable {
    let files: any VaultFileStore

    package func execute(_ path: VaultPath, expected: ContentHash?, change: (String) throws -> String) async throws -> ContentHash {
        let current = try await files.read(path)
        guard FileKindPolicy.mayBeText(path, size: current.meta.size), let text = FileKindPolicy.text(from: current.data) else {
            throw AgentError.notText(path.rawValue)
        }
        if let expected, expected != current.hash {
            throw AgentError.staleFile
        }
        switch try await files.write(path, data: Data(try change(text).utf8), expected: current.hash) {
        case .written(let hash):
            return hash
        case .conflict:
            throw AgentError.staleFile
        }
    }
}
