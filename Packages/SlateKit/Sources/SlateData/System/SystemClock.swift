import Foundation
import SlateDomain

struct SystemClock: Clock {
    func now() -> Date {
        Date()
    }

    var timeZone: TimeZone {
        .current
    }
}
