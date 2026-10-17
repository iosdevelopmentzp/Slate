import Foundation

nonisolated package struct TableColumn: Hashable, Sendable {
    package var alignment: TableAlignment

    package init(alignment: TableAlignment = .none) {
        self.alignment = alignment
    }
}
