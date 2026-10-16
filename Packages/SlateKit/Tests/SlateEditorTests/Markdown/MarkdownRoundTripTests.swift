import Foundation
import Markdown
import Testing
@testable import SlateEditor

@MainActor
@Suite struct MarkdownRoundTripTests {

    static func fixtures(_ folder: String) throws -> [URL] {
        let base = try #require(Bundle.module.url(forResource: "Fixtures", withExtension: nil)).appendingPathComponent(folder)
        return try FileManager.default.contentsOfDirectory(at: base, includingPropertiesForKeys: nil).filter { $0.pathExtension == "md" }.sorted { $0.path < $1.path }
    }

    static func ast(_ markdown: String) -> String {
        Document(parsing: markdown, options: [.disableSmartOpts]).debugDescription()
            .split(separator: "\n")
            .map { line in line.replacingOccurrences(of: #" @\S+"#, with: "", options: .regularExpression) }
            .map { $0.replacingOccurrences(of: #"OrderedList start: \d+"#, with: "OrderedList", options: .regularExpression) }
            .joined(separator: "\n")
    }

    @Test func filesSlateWroteComeBackByteForByte() throws {
        let files = try Self.fixtures("RoundTrip")
        #expect(files.count >= 4)
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            let written = MarkdownWriter.write(MarkdownReader.read(source))
            if written != source {
                let a = written.components(separatedBy: "\n"), b = source.components(separatedBy: "\n")
                for (i, line) in b.enumerated() where i >= a.count || a[i] != line {
                    Issue.record("\(file.lastPathComponent):\(i + 1) want <\(line)> got <\(i < a.count ? a[i] : "EOF")>\n\(written)")
                    break
                }
            }
        }
    }

    @Test func filesFromOtherToolsKeepTheirMeaning() throws {
        for file in try Self.fixtures("Foreign") {
            let source = try String(contentsOf: file, encoding: .utf8)
            let written = MarkdownWriter.write(MarkdownReader.read(source))
            #expect(Self.ast(written) == Self.ast(source), "\(file.lastPathComponent)\n\(written)")
            #expect(MarkdownWriter.write(MarkdownReader.read(written)) == written, "\(file.lastPathComponent) is stable")
        }
    }
}
