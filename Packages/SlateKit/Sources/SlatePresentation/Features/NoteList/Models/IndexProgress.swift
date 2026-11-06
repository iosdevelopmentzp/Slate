import Foundation

struct IndexProgress: Equatable {
    static let minimumTotal = 400

    let done: Int
    let total: Int

    init?(done: Int, total: Int) {
        guard total >= Self.minimumTotal, done < total else { return nil }
        self.done = done
        self.total = total
    }

    var fraction: Double {
        Double(done) / Double(total)
    }

    var text: String {
        "Reading notes, \(done.formatted()) of \(total.formatted())"
    }
}
