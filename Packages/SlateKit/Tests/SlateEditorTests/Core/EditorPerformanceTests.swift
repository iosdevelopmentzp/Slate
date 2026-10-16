import AppKit
import Testing
@testable import SlateEditor

@Suite struct EditorPerformanceTests {
    @Test func longNoteOpensAndTypesWithinBudget() throws {
        let text = try EditorHarness.fixture("LongNote")
        let clock = ContinuousClock()
        var harness: EditorHarness?
        let open = clock.measure {
            harness = EditorHarness(text: text, resolveImage: { _ in Self.sampleImageURL })
        }
        let editor = try #require(harness)
        let middle = (text as NSString).length / 2
        var samples: [Duration] = []
        for index in 0..<60 {
            let location = middle + index
            samples.append(clock.measure { editor.type("a", at: location) })
        }
        let fenceEdit = clock.measure { editor.type("```\n", at: middle) }
        let sorted = samples.sorted()
        let median = sorted[sorted.count / 2]
        let worst = sorted[sorted.count - 2]
        print("editor timing: open=\(open) median=\(median) p97=\(worst) fence=\(fenceEdit)")
        #expect(median < .milliseconds(16))
    }

    @Test func imageLineGetsRoomForTheImage() throws {
        let harness = EditorHarness(text: "![](a.png)\nnext", resolveImage: { _ in Self.sampleImageURL })
        let layoutManager = try #require(harness.textView.textLayoutManager)
        var frames: [CGRect] = []
        layoutManager.enumerateTextLayoutFragments(from: layoutManager.documentRange.location, options: [.ensuresLayout]) { fragment in
            frames.append(fragment.layoutFragmentFrame)
            return true
        }
        print("editor image frames=\(frames)")
        #expect(frames.count >= 2)
        #expect(frames[0].height > 100)
        #expect(frames[1].minY >= frames[0].maxY)
    }

    private static let sampleImageURL: URL = {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("slate-editor-sample.png")
        let image = NSImage(size: NSSize(width: 400, height: 200), flipped: false) { rect in
            NSColor.systemBlue.setFill()
            rect.fill()
            return true
        }
        if let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: url)
        }
        return url
    }()
}
