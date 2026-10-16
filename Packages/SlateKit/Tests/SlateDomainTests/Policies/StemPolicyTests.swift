import Testing
@testable import SlateDomain

@Suite struct StemPolicyTests {
    @Test(arguments: [
        ("  Hello  ", "Hello"),
        ("a/b:c", "a-b-c"),
        ("What? *Now* <x> | \"y\" \\z", "What Now x y z"),
        ("tab\tand\n\nlines", "tab and lines"),
        ("..dots and spaces.. ", "dots and spaces"),
        ("", "Untitled"),
        ("???", "Untitled"),
        ("ABC-2324 Profile screen leaks memory", "ABC-2324 Profile screen leaks memory"),
    ])
    func sanitisesTitles(title: String, stem: String) {
        #expect(StemPolicy.stem(forTitle: title) == stem)
    }

    @Test func cutsTo120CharactersAndTrimsAgain() {
        let title = String(repeating: "a", count: 119) + " bbbb"

        let stem = StemPolicy.stem(forTitle: title)

        #expect(stem == String(repeating: "a", count: 119))
    }

    @Test func cutsOnGraphemeBoundaries() {
        let title = String(repeating: "👩‍👩‍👧", count: 130)

        #expect(StemPolicy.stem(forTitle: title).count == 120)
    }

    @Test func uniqueAddsANumberCaseInsensitively() {
        #expect(StemPolicy.unique("Name", among: []) == "Name")
        #expect(StemPolicy.unique("Name", among: ["name"]) == "Name 2")
        #expect(StemPolicy.unique("Name", among: ["Name", "Name 2", "NAME 3"]) == "Name 4")
    }
}
