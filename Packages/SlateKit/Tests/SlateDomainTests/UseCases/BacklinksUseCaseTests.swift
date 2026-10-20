import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct BacklinksUseCaseTests {
    private let ports: Ports
    private let spies: PortSpies

    init() {
        (ports, spies) = Ports.spies()
    }

    @Test func notesThatLinkHereComeWithTheLineAroundTheLink() async throws {
        let useCases = UseCases(ports: ports)
        let target = try await useCases.create.execute(NoteDraft(title: "Plan", space: SpaceName(rawValue: "Notes")))
        _ = try await useCases.create.execute(NoteDraft(title: "Daily", space: SpaceName(rawValue: "Notes"), body: "Intro\n\nWe follow the **[[Plan]]** for now.\n"))
        _ = try await useCases.create.execute(NoteDraft(title: "Review", space: SpaceName(rawValue: "Notes"), body: "Read [the plan](Plan.md) first.\n"))
        _ = try await useCases.create.execute(NoteDraft(title: "Other", space: SpaceName(rawValue: "Notes"), body: "No link.\n"))

        let backlinks = try await useCases.backlinks.execute(for: target.document.path)

        #expect(Set(backlinks.map(\.note.title)) == ["Daily", "Review"])
        #expect(backlinks.first { $0.note.title == "Daily" }?.context == "We follow the Plan for now.")
        #expect(backlinks.first { $0.note.title == "Review" }?.context == "Read the plan first.")
    }

    @Test func aLongLineIsCut() {
        let line = String(repeating: "word ", count: 60) + "[[Plan]]"

        let context = BacklinksUseCase.context(of: line)

        #expect(context.count <= BacklinksUseCase.contextLength + 1)
        #expect(context.hasSuffix("…"))
    }
}
