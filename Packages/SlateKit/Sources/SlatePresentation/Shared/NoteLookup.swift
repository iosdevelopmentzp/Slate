import Foundation
import SlateDomain

@MainActor
protocol NoteLookup: AnyObject {
    var summaries: [NoteSummary] { get }
}
