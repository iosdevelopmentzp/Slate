import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct AttachScreenshotUseCaseTests {
    private let note = VaultPath(rawValue: "Tasks/A.md")

    @Test func aCaptureBecomesAnImageLink() async throws {
        let (ports, spies) = Ports.spies()

        let markdown = try await UseCases(ports: ports).attachScreenshot.execute(.region, for: note)

        #expect(markdown == "![](../_attachments/20270115-110000-screenshot.png)")
        #expect(spies.capture.calls == [.region])
    }

    @Test func aWindowCaptureIsNamedWindow() async throws {
        let (ports, _) = Ports.spies()

        let markdown = try await UseCases(ports: ports).attachScreenshot.execute(.window, for: note)

        #expect(markdown == "![](../_attachments/20270115-110000-window.png)")
    }

    @Test func aCancelledCaptureGivesNothing() async throws {
        let (ports, spies) = Ports.spies()
        spies.capture.producesFile = false

        let markdown = try await UseCases(ports: ports).attachScreenshot.execute(.region, for: note)

        #expect(markdown == nil)
    }
}
