import Foundation
import SlateDomain
import SlateUI

@MainActor
final class SubscriptionToken {
    private let cancel: () -> Void

    init(cancel: @escaping () -> Void) {
        self.cancel = cancel
    }

    isolated deinit {
        cancel()
    }
}
