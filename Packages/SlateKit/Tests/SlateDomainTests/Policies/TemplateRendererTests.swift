import Foundation
import Testing
@testable import SlateDomain

@Suite struct TemplateRendererTests {
    @Test func replacesPlaceholdersAndRemovesTheCursor() {
        let rendered = TemplateRenderer.render("# {{title}}\n\n{{cursor}}\n\nEnd", values: ["title": "Hello"])

        #expect(rendered.text == "# Hello\n\n\n\nEnd")
        #expect(rendered.caret == 9)
    }

    @Test func caretGoesToTheEndWithoutACursor() {
        let rendered = TemplateRenderer.render("abc", values: [:])

        #expect(rendered.caret == 3)
    }

    @Test func caretCountsUTF16Units() {
        let rendered = TemplateRenderer.render("👍{{cursor}}", values: [:])

        #expect(rendered.caret == 2)
    }

    @Test func valuesUseTheLocalDateAndTime() {
        let zone = TimeZone(secondsFromGMT: 3 * 3_600) ?? .gmt
        let now = Date(timeIntervalSince1970: 1_792_131_153)

        let values = TemplateRenderer.values(title: "T", header: NoteHeader(ticket: "ABC-1"), now: now, timeZone: zone)

        #expect(values["date"] == "2026-10-16")
        #expect(values["time"] == "09:12")
        #expect(values["weekday"] == "Friday")
        #expect(values["ticket"] == "ABC-1")
        #expect(values["branch"] == "")
        #expect(values["datetime"] == "2026-10-16T09:12:33+03:00")
    }

    @Test func builtInTaskTemplatePutsTheCaretUnderContext() {
        let template = BuiltInTemplates.bodies["task"] ?? ""

        let rendered = TemplateRenderer.render(template, values: [:])

        #expect(rendered.text.hasPrefix("## Context\n\n\n\n## Plan"))
        #expect(rendered.caret == "## Context\n\n".utf16.count)
    }
}
