import Foundation
import SlateDomain

struct MockClock: Clock {
    func now() -> Date {
        MockVault.reference
    }

    var timeZone: TimeZone {
        .gmt
    }
}
