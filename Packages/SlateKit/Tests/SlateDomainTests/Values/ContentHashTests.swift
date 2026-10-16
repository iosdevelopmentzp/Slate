import Foundation
import Testing
@testable import SlateDomain

@Suite struct ContentHashTests {
    @Test func isTheSHA256HexOfTheBytes() {
        #expect(ContentHash.of(Data("abc".utf8)).rawValue == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}
