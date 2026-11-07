import Foundation
import SlateDomain
import Testing
@testable import SlateData

@Suite struct ScreencaptureToolTests {
    @Test func regionArguments() {
        #expect(ScreencaptureTool.arguments(for: .region, path: "/v/a.png") == ["-i", "-x", "-t", "png", "/v/a.png"])
    }

    @Test func windowArguments() {
        #expect(ScreencaptureTool.arguments(for: .window, path: "/v/a.png") == ["-i", "-W", "-o", "-x", "-t", "png", "/v/a.png"])
    }

    @Test func theSimulatorShotUsesSimctl() {
        #expect(ScreencaptureTool.executable(for: .simulator) == "xcrun")
        #expect(ScreencaptureTool.arguments(for: .simulator, path: "/v/a.png") == ["simctl", "io", "booted", "screenshot", "--type=png", "/v/a.png"])
    }
}
