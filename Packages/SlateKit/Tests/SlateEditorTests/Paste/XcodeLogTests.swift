import Testing
@testable import SlateEditor

@Suite struct XcodeLogTests {
    @Test func theDateProcessAndThreadGo() {
        let log = """
        2026-11-07 14:03:21.123456+0200 MyApp[12345:678901] [Network] Request started
        2026-11-07 14:03:21.456789+0200 MyApp[12345:678955] Response 200
        """

        #expect(XcodeLog.cleaned(log) == "[Network] Request started\nResponse 200")
    }

    @Test func logStreamLinesAreCleanedToo() {
        let line = "2026-11-07 14:03:21.123456+0200 0x1a2b3c   Default     0x0                  12345  0    MyApp: (Network) Done"

        #expect(XcodeLog.cleaned(line) == "(Network) Done")
    }

    @Test func ordinaryTextIsLeftAlone() {
        #expect(XcodeLog.cleaned("Just a line\nAnd another") == nil)
    }

    @Test func aLogPastesAsALogCodeBlock() {
        let block = CodeText.block(from: "2026-11-07 14:03:21.123456+0200 MyApp[1:2] a\n2026-11-07 14:03:22.000000+0200 MyApp[1:2] b\n")

        #expect(block == CodeText.Block(code: "a\nb", language: "log"))
    }
}
