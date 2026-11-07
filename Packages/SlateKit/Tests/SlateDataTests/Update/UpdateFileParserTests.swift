import Foundation
import SlateDomain
import Testing
@testable import SlateData

@Suite struct UpdateFileParserTests {
    @Test func theInstalledBuildIsRead() {
        let json = #"{"commit": "abc123", "branch": "main", "source": "/s/source", "installedAt": "2026-11-07T10:00:00Z"}"#

        #expect(UpdateFileParser.installed(Data(json.utf8)) == InstalledBuild(commit: "abc123", branch: "main", source: "/s/source"))
        #expect(UpdateFileParser.installed(Data(#"{"commit": "", "source": "/s"}"#.utf8)) == nil)
    }

    @Test func theStatusIsRead() {
        let json = #"{"phase": "building", "startedAt": "2026-11-07T10:00:00Z", "commit": "", "message": ""}"#

        let status = UpdateFileParser.status(Data(json.utf8))

        #expect(status?.phase == .building)
        #expect(status?.startedAt == Date(timeIntervalSince1970: 1_794_045_600))
        #expect(status?.commit == nil)
        #expect(UpdateFileParser.status(Data(#"{"phase": "dancing"}"#.utf8)) == nil)
    }

    @Test func gitLogLinesBecomeCommits() {
        #expect(UpdateFileParser.commits("a1b2c3d\u{1F}feat: one\nb2c3d4e\u{1F}fix: two\n") == [
            UpdateCommit(hash: "a1b2c3d", subject: "feat: one"),
            UpdateCommit(hash: "b2c3d4e", subject: "fix: two"),
        ])
    }
}
