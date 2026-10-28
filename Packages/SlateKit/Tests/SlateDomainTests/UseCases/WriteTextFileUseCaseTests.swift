import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct WriteTextFileUseCaseTests {
    private let ports: Ports
    private let spies: PortSpies
    private let path = VaultPath(rawValue: "Work/App.swift")

    init() {
        (ports, spies) = Ports.spies()
    }

    @Test func writesTheChangedTextOverTheReadHash() async throws {
        let hash = spies.files.seed(path, "let a = 1")

        let written = try await UseCases(ports: ports).writeTextFile.execute(path, expected: hash) { $0 + "\n" }

        #expect(spies.files.text(at: path) == "let a = 1\n")
        #expect(written == ContentHash.of(Data("let a = 1\n".utf8)))
        #expect(spies.files.calls.contains(.write(path, expected: hash)))
    }

    @Test func aDifferentExpectedHashIsRefused() async throws {
        spies.files.seed(path, "let a = 1")

        await #expect(throws: AgentError.staleFile) {
            try await UseCases(ports: ports).writeTextFile.execute(path, expected: ContentHash(rawValue: "old")) { _ in "x" }
        }
        #expect(spies.files.text(at: path) == "let a = 1")
    }

    @Test func aFileThatIsNotTextIsRefused() async throws {
        let image = VaultPath(rawValue: "Work/shot.png")
        spies.files.seed(image, "png")
        let blob = VaultPath(rawValue: "Work/data.bin2")
        spies.files.seed(blob, "a\u{0}b")

        await #expect(throws: AgentError.notText(image.rawValue)) {
            try await UseCases(ports: ports).writeTextFile.execute(image, expected: nil) { _ in "x" }
        }
        await #expect(throws: AgentError.notText(blob.rawValue)) {
            try await UseCases(ports: ports).writeTextFile.execute(blob, expected: nil) { _ in "x" }
        }
    }
}
