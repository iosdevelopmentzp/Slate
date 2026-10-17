import Foundation
import Testing
@testable import SlateEditor

@Suite struct ImageSizeTests {
    @Test func readsTheWidthFromTheEndOfTheAltText() {
        #expect(ImageSize.width(in: "photo|300") == 300)
        #expect(ImageSize.width(in: "|120") == 120)
        #expect(ImageSize.width(in: "photo|300x200") == 300)
        #expect(ImageSize.width(in: "photo") == nil)
        #expect(ImageSize.width(in: "photo|wide") == nil)
        #expect(ImageSize.width(in: nil) == nil)
    }

    @Test func theLabelIsThePartBeforeTheSize() {
        #expect(ImageSize.label(of: "photo|300x200") == "photo")
        #expect(ImageSize.label(of: "a|b") == "a|b")
    }

    @Test func settingAWidthReplacesOrRemovesTheSuffix() {
        #expect(ImageSize.alt("photo", width: 240) == "photo|240")
        #expect(ImageSize.alt("photo|300x200", width: 420) == "photo|420")
        #expect(ImageSize.alt("photo|300", width: nil) == "photo")
        #expect(ImageSize.alt("|300", width: nil) == nil)
        #expect(ImageSize.alt(nil, width: 60) == "|60")
    }
}
