import Foundation
import Testing
@testable import SlateDomain

@Suite struct ImageTypePolicyTests {
    private func data(_ prefix: [UInt8]) -> Data {
        Data(prefix + [UInt8](repeating: 0, count: 16))
    }

    @Test func knownImagesGetTheirExtension() {
        #expect(ImageTypePolicy.fileExtension(of: data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) == "png")
        #expect(ImageTypePolicy.fileExtension(of: data([0xFF, 0xD8, 0xFF, 0xE0])) == "jpg")
        #expect(ImageTypePolicy.fileExtension(of: data(Array("GIF89a".utf8))) == "gif")
        #expect(ImageTypePolicy.fileExtension(of: data(Array("RIFF".utf8) + [0, 0, 0, 0] + Array("WEBP".utf8))) == "webp")
        #expect(ImageTypePolicy.fileExtension(of: data([0, 0, 0, 24] + Array("ftypheic".utf8))) == "heic")
    }

    @Test func otherDataIsNotAnImage() {
        #expect(ImageTypePolicy.fileExtension(of: Data("hello, this is text".utf8)) == nil)
        #expect(ImageTypePolicy.fileExtension(of: Data([0x89, 0x50])) == nil)
        #expect(ImageTypePolicy.fileExtension(of: data([0x25, 0x50, 0x44, 0x46])) == nil)
    }
}
