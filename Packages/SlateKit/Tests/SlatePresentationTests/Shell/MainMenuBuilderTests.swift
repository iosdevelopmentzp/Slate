import AppKit
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct MainMenuBuilderTests {
    @Test func viewMenuOffersTheAppearanceWithTheCurrentChoiceTicked() throws {
        var current = AppAppearance.system
        let target = MenuTarget()
        let appearance = AppAppearance.allCases.map { choice in
            MainMenuBuilder.Command(title: choice.title, key: "", modifiers: [], isOn: { current == choice }) { current = choice }
        }
        let menu = MainMenuBuilder(app: [], file: [], note: [], go: [], view: [], appearance: appearance, target: target).build()

        let view = try #require(menu.item(withTitle: "View")?.submenu)
        let submenu = try #require(view.item(withTitle: "Appearance")?.submenu)
        #expect(submenu.items.map(\.title) == ["Match the system", "Light", "Dark"])

        let dark = submenu.items[2]
        target.perform(dark)
        #expect(current == .dark)
        submenu.items.forEach { _ = target.validateMenuItem($0) }
        #expect(submenu.items.map(\.state) == [.off, .off, .on])
    }
}
